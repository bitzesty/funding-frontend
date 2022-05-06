class FundingApplication::ProgressAndSpend::PreviousSubmissions::PreviousSubmissionDatesController < ApplicationController
  include FundingApplicationContext

  def show
    @previous_submissions = @funding_application.completed_arrears_journeys
  end

end
