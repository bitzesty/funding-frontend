class FundingApplication::ProgressAndSpend::ProgressUpdate::\
  Volunteer::VolunteerAddController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()
    @volunteer = 
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_volunteer.build

  end
  
  def update() 
    @volunteer = 
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_volunteer.build

    update_validate_redirect_volunteer(@volunteer, @funding_application)
    
  end

end
