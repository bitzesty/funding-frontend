class FundingApplication::ProgressAndSpend::ProgressUpdate::Procurement::ProcurementReportController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()
    get_attachments
    initialize_view
  end

  def update()
    progress_update.validate_has_procurement_report_evidence = true

    progress_update.has_procurement_report_evidence =
      params[:progress_update].nil? ? nil : 
        params[:progress_update][:has_procurement_report_evidence]

    if progress_update.has_procurement_report_evidence == "true"
      progress_update.validate_progress_updates_procurement_evidence = true
    end

    if params.has_key?(:save_and_continue_button)
      save_json
      if progress_update.valid?
        if progress_update.has_procurement_report_evidence == "true" && has_additional_grant_conditions?
          redirect_to(
            funding_application_progress_and_spend_progress_update_additional_grant_conditions_path(
              progress_update_id:  \
                @funding_application.arrears_journey_tracker.progress_update.id
            )
          )
        elsif progress_update.has_procurement_report_evidence == "false" 

          # If there are already existing procurements (this is a return journey)
          # then route to procurements summary. 
          if progress_update.progress_update_procurement.empty?
            redirect_to(
              funding_application_progress_and_spend_progress_update_procurement_add_procurement_path(
                progress_update_id:  \
                  @funding_application.arrears_journey_tracker.progress_update.id
              )
            )
          else
            redirect_to(
              funding_application_progress_and_spend_progress_update_procurement_procurements_summary_path(
                progress_update_id:  \
                  @funding_application.arrears_journey_tracker.progress_update.id
              )
            )
          end
        else
          redirect_to(
            funding_application_progress_and_spend_progress_update_completion_date_path(
                progress_update_id:
                  @funding_application.arrears_journey_tracker.progress_update.id
            )
          )
        end
        
      else
        rerender
      end
    end

    # Form submitted to delete a file. 
    if params.has_key?(:delete_file_button)
      delete(params[:delete_file_button]) 
    end

    # Form submitted to add a file.
    if params.has_key?(:add_file_button)
      save_json
      progress_update.update( get_params )
      rerender
    end
  end

  private

  def initialize_view()
    if  progress_update.answers_json['procurements']['has_procurement_report_evidence'] == true.to_s
      progress_update.has_procurement_report_evidence = true.to_s
    elsif  progress_update.answers_json['procurements']['has_procurement_report_evidence'] == false.to_s
      progress_update.has_procurement_report_evidence = false.to_s
    end
  end

  def rerender()
      initialize_view
      get_attachments
      render :show
  end
 
  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end

  def get_attachments
    @attachments_hash = Hash.new
    @funding_application.arrears_journey_tracker.progress_update
      .progress_update_procurement_evidence&.map{ |attachment|  
        @attachments_hash[attachment.id] = attachment.progress_update_procurement_evidence_file_blob}
  end

  def delete(progress_event_id)
    save_json
    progress_update_event =  @funding_application.arrears_journey_tracker
      .progress_update.progress_update_procurement_evidence.find(progress_event_id)
    progress_update_event.destroy

    logger.info "Removed progress_update_procurement_evidence_file with id: " \
      "#{progress_event_id} for progress update " \
        "#{@funding_application.arrears_journey_tracker.progress_update.id}"

    redirect_to(
      funding_application_progress_and_spend_progress_update_procurement_procurement_report_path(
        progress_update_id:  \
          @funding_application.arrears_journey_tracker.progress_update.id
      )
    )

  end

  def get_params
    params.fetch(:progress_update, {}).permit(
      progress_update_procurement_evidence_attributes:[
        :progress_update_procurement_evidence_file
      ]
    )
  end

  def save_json()
    answers_json = progress_update.answers_json
    answers_json['procurements']['has_procurement_report_evidence'] = progress_update.has_procurement_report_evidence

    progress_update.answers_json = answers_json
    progress_update.save
  end 

  def has_additional_grant_conditions?
    salesforce_additional_grant_conditions(@funding_application).any?
  end

end
