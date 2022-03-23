class FundingApplication::ProgressAndSpend::SelectJourneyController < ApplicationController
include FundingApplicationContext

  def show()
  
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
        payment_request = @funding_application.payment_requests.create  
        @funding_application.arrears_journey_tracker.update(
          payment_request_id: payment_request.id
        )
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
          progress_update.answers_json['photos'] = { }
          progress_update.answers_json['events'] = { }
          progress_update.answers_json['new_staff'] = { }
          progress_update.answers_json['procurements'] = { }
          progress_update.answers_json['new_expiry_date'] = { }
          progress_update.answers_json['statutory_permissions_licences'] = { }
          progress_update.answers_json['risk'] = { }
          progress_update.answers_json['cash_contributions'] = { }
          progress_update.save
        end
       
      end
    end

    if @funding_application.arrears_journey_tracker.valid?
      redirect_to \
        funding_application_progress_and_spend_progress_and_spend_tasks_path
    else
      render :show
    end
   
  end

end
