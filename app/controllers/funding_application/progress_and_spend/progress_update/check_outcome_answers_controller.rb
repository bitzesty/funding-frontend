class FundingApplication::ProgressAndSpend::ProgressUpdate::CheckOutcomeAnswersController < ApplicationController
  include FundingApplicationContext
  include Enums::ArrearsJourneyStatus

  def show()

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

  def update()

    @funding_application.arrears_journey_tracker.progress_update.\
      answers_json['journey_status']['approved_purposes'] \
        = JOURNEY_STATUS[:completed]

    @funding_application.arrears_journey_tracker.progress_update.save

    redirect_to(
      funding_application_progress_and_spend_progress_and_spend_tasks_path()
    )

  end

end
