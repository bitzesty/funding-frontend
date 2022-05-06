class FundingApplication::ProgressAndSpend::PreviousSubmissions::PreviouslySubmittedController < ApplicationController
  include FundingApplicationContext
  
  def show
    get_previous_submission
  end

  private

  def get_previous_submission
  @previous_submission = 
    @funding_application.completed_arrears_journeys
      .find(params[:completed_arrears_journey_id])
  end

end
