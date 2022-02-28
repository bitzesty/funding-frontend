class FundingApplication::ProgressAndSpend::SelectJourneyController < ApplicationController
include FundingApplicationContext

  def show()
  

  end

  # At the point that an applicant clicks update, we create the payment request and progress_update 
  # objects.  And this means they are not shown the select journey page again.
  def update()

    if @funding_application.arrears_journey_tracker.payment_request_id.blank?
      payment_request = @funding_application.payment_requests.create  
      @funding_application.arrears_journey_tracker.update(
        payment_request_id: payment_request.id
      )
    end

    if @funding_application.arrears_journey_tracker.progress_update_id.blank?
      progress_update = @funding_application.progress_updates.create  
      @funding_application.arrears_journey_tracker.update(
        progress_update_id:  progress_update.id
      )
    end
    
    redirect_to \
      funding_application_progress_and_spend_progress_and_spend_tasks_path

  end

end
