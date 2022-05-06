class FundingApplication::ProgressAndSpend::PreviousSubmissions::SubmissionSummary::ApprovedPurposesSubmissionController < ApplicationController
  include FundingApplicationContext

  def show

    @approved_purposes =
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_approved_purpose

    @demographic =
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_demographic.first

    @optional_outcomes_progress_updates =
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_outcome.first.progress_updates

  end

  def update
    redirect_to funding_application_progress_and_spend_previous_submissions_previously_submitted_path(
      completed_arrears_journey_id: params[:completed_arrears_journey_id] )
  end
end
