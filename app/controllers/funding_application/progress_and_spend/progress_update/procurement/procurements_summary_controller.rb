class FundingApplication::ProgressAndSpend::ProgressUpdate::Procurement::ProcurementsSummaryController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show() 
    get_procurements
  end

  def update()

    progress_update.validate_add_another_procurement = true

    progress_update.add_another_procurement = 
    params[:progress_update].nil? ? nil : 
      params[:progress_update][:add_another_procurement]

    if progress_update.valid?
      if progress_update.add_another_procurement == "true"
        redirect_to(
          funding_application_progress_and_spend_progress_update_procurement_add_procurement_path(
            progress_update_id:  \
              @funding_application.arrears_journey_tracker.progress_update.id
          )
        )
      elsif progress_update.add_another_procurement == "false" && has_additional_grant_conditions?
        redirect_to(
          funding_application_progress_and_spend_progress_update_additional_grant_conditions_path(
            progress_update_id:  \
              @funding_application.arrears_journey_tracker.progress_update.id
          )
        )
      else
         # No additional grant conditions - go to question about completion date
         redirect_to(
          funding_application_progress_and_spend_progress_update_completion_date_path(
              progress_update_id:
                @funding_application.arrears_journey_tracker.progress_update.id
          )
        )
      end
    else
      get_procurements 
      render :show
    end

  end

  def delete()
     logger.info(
      'Deleting procurement with id: ' \
      "#{params[:procurement_id]} from propress_update ID: " \
      "#{params[:progress_update_id]}"
    )

    procurement = progress_update.progress_update_procurement.find(params[:procurement_id])
    
    procurement.destroy

    get_procurements
    render :show

  end

  private 

  def get_procurements
    @procurements = @funding_application.arrears_journey_tracker
      .progress_update.progress_update_procurement
  end

  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end

  def has_additional_grant_conditions?
    salesforce_additional_grant_conditions(@funding_application).any?
  end

end
