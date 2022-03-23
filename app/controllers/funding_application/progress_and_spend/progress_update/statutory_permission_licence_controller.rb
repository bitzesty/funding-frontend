class FundingApplication::ProgressAndSpend::ProgressUpdate::StatutoryPermissionLicenceController < ApplicationController
  include FundingApplicationContext
  
  def show()
    get_attachments
    initialize_view
  end

  def update()  
    progress_update.validate_has_statutory_permissions_licence = true

    progress_update.has_statutory_permissions_licence =
      params[:progress_update].nil? ? nil : 
        params[:progress_update][:has_statutory_permissions_licence]

    if progress_update.has_statutory_permissions_licence == "true"
      progress_update.validate_progress_update_statutory_permissions_licence = true
    end

    if params.has_key?(:save_and_continue_button)
      save_json
      if progress_update.valid?
        
        redirect_to(
          funding_application_progress_and_spend_progress_update_risk_risk_question_path(
            progress_update_id:  \
              @funding_application.arrears_journey_tracker.progress_update.id
          )
        )

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
    if  progress_update.answers_json['statutory_permissions_licences']\
      ['has_statutory_permissions_licence'] == true.to_s
      progress_update.has_statutory_permissions_licence = true.to_s
    elsif  progress_update.answers_json['statutory_permissions_licences']\
      ['has_statutory_permissions_licence'] == false.to_s
      progress_update.has_statutory_permissions_licence = false.to_s
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
      .progress_update_statutory_permissions_licence&.map{|attachment| \
          @attachments_hash[attachment.id] = \
            attachment.progress_update_statutory_permissions_licence_file_blob}
  end

  def delete(statutory_permission_licence_id)
    save_json

    statutory_permission_licence =  
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_statutory_permissions_licence.find(
          statutory_permission_licence_id
        )
    statutory_permission_licence.destroy

    logger.info "Removed progress_update_statutory_permissions_licence "
      "with id: #{statutory_permission_licence_id} for progress update " \
        "#{@funding_application.arrears_journey_tracker.progress_update.id}"

    redirect_to(
      funding_application_progress_and_spend_progress_update_permissions_or_licences_path(
          progress_update_id:  \
            @funding_application.arrears_journey_tracker.progress_update.id
        )
    )

  end

  def get_params
    params.fetch(:progress_update, {}).permit(
      progress_update_statutory_permissions_licence_attributes:[
        :progress_update_statutory_permissions_licence_file
      ]
    )
  end

  def save_json()
    answers_json = progress_update.answers_json
    answers_json['statutory_permissions_licences']['has_statutory_permissions_licence'] = progress_update.has_statutory_permissions_licence

    progress_update.answers_json = answers_json
    progress_update.save
  end
  
  
  end
