class FundingApplication::ProgressAndSpend::SelectJourneyController < ApplicationController
include FundingApplicationContext
include ProgressAndSpendHelper
include Enums::ArrearsJourneyStatus

  def show()
    retrieve_project_info

    if @funding_application.arrears_journey_tracker.payment_request_id.present? ||
      @funding_application.arrears_journey_tracker.progress_update_id.present?
    
      redirect_to \
        funding_application_progress_and_spend_progress_and_spend_tasks_path()
    end

  end

  # At the point that an applicant clicks update, we create the payment request and progress_update 
  # objects.  And this means they are not shown the select journey page again.
  def update()

    @funding_application.arrears_journey_tracker.get_payment = 
      params[:arrears_journey_tracker][:get_payment].nil? ? nil :
        params[:arrears_journey_tracker][:get_payment] 

    @funding_application.arrears_journey_tracker.give_project_update = 
      params[:arrears_journey_tracker][:give_project_update].nil? ? nil :
        params[:arrears_journey_tracker][:give_project_update] 
  

    @funding_application.arrears_journey_tracker.validate_journey_selection = true

    if  @funding_application.arrears_journey_tracker.get_payment == "true"

      if @funding_application.arrears_journey_tracker.payment_request_id.blank?

        payment_request = @funding_application.payment_requests.create(
          answers_json: {
            arrears_journey: {
              status: JOURNEY_STATUS[:not_started],
              spend_journeys_to_do:[]
            },
            bank_details_journey: {
              status: JOURNEY_STATUS[:not_started],
              has_bank_details_update: nil
            }
          }
        )

        @funding_application.arrears_journey_tracker.update(
          payment_request_id: payment_request.id)

      end
    end


    if @funding_application.arrears_journey_tracker.give_project_update == "true"
      if @funding_application.arrears_journey_tracker.progress_update_id.blank?
        progress_update = @funding_application.progress_updates.create  
        @funding_application.arrears_journey_tracker.update(
          progress_update_id:  progress_update.id
        )
  
        if progress_update.answers_json.blank? 
          progress_update.answers_json = Hash.new 

          progress_update.answers_json['journey_status'] = {}
          progress_update.answers_json['journey_status']['approved_purposes'] \
            = JOURNEY_STATUS[:not_started]
          progress_update.answers_json['journey_status']['how_project_going'] \
            = JOURNEY_STATUS[:not_started]

          progress_update.answers_json['photos'] = { }
          progress_update.answers_json['events'] = { }
          progress_update.answers_json['additional_grant_condition'] = { }
          progress_update.answers_json['new_staff'] = { }
          progress_update.answers_json['procurements'] = { }
          progress_update.answers_json['new_expiry_date'] = { }
          progress_update.answers_json['statutory_permissions_licences'] = { }
          progress_update.answers_json['risk'] = { }
          progress_update.answers_json['cash_contribution'] = { 'records': {} }
          progress_update.answers_json['volunteer'] = { }
          progress_update.answers_json['non_cash_contribution'] = { }
          progress_update.answers_json['approved_purpose'] = { }
          progress_update.save
        end
       
      end
    end

    if @funding_application.arrears_journey_tracker.valid?
      redirect_to \
        funding_application_progress_and_spend_progress_and_spend_tasks_path
    else
      retrieve_project_info
      render :show
    end
   
  end

  private

  def retrieve_project_info

    details_hash = salesforce_arrears_project_details(@funding_application)

    @project_name = details_hash[:project_name]
    @project_reference_num = @funding_application.project_reference_number
    @grant_paid = details_hash[:amount_paid] 
    @remaining_grant = details_hash[:amount_remaining]
    @grant_expiry_date = details_hash[:project_expiry_date]

  end
  
end
