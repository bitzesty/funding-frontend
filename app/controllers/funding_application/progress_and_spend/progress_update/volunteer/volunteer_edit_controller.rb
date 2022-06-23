class FundingApplication::ProgressAndSpend::ProgressUpdate::\
  Volunteer::VolunteerEditController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()
    get_volunteer
  end

  def update()
    get_volunteer

    update_validate_redirect_volunteer(@volunteer, @funding_application)

  end

  private

  def get_volunteer()
    begin
      @volunteer = 
        @funding_application.arrears_journey_tracker.progress_update.\
          progress_update_volunteer.find(params[:volunteer_id])
    rescue ActiveRecord::RecordNotFound  
      redirect_to(
        funding_application_progress_and_spend_progress_update_volunteer_volunteer_summary_path(
            progress_update_id:
              @funding_application.arrears_journey_tracker.progress_update.id
        )
      )
      return
    end
  end
end
