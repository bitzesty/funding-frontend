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
  @volunteer = 
    @funding_application.arrears_journey_tracker.progress_update.\
      progress_update_volunteer.find(params[:volunteer_id])
  end
end
