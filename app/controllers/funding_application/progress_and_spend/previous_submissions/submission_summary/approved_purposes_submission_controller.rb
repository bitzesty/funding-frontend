class FundingApplication::ProgressAndSpend::PreviousSubmissions::SubmissionSummary::ApprovedPurposesSubmissionController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show

    previous_submission =
      @funding_application.completed_arrears_journeys
        .find(params[:completed_arrears_journey_id])

    @digital_output = get_digital_output_if_required(
      previous_submission&.progress_update
    )

    @approved_purposes =
      previous_submission&.progress_update&.\
        progress_update_approved_purpose

    @demographic =
      previous_submission&.progress_update&.\
        progress_update_demographic&.first

    @optional_outcomes_progress_updates =
      previous_submission&.progress_update&.\
        progress_update_outcome&.first&.progress_updates

    @funding_acknowledgments =
      previous_submission&.progress_update&.\
        progress_update_funding_acknowledgement&.first&.acknowledgements

  end

  def update
    redirect_to funding_application_progress_and_spend_previous_submissions_previously_submitted_path(
      completed_arrears_journey_id: params[:completed_arrears_journey_id] )
  end

end
