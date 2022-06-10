class FundingApplication::ProgressAndSpend::ProgressUpdate::CheckYourAnswersController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  include Enums::ArrearsJourneyStatus

  def show()
    initialise_view
  end

  def update()

    progress_update.answers_json['journey_status']['how_project_going'] \
      = JOURNEY_STATUS[:completed]
    progress_update.save

    redirect_to(
      funding_application_progress_and_spend_progress_and_spend_tasks_path()
    )

  end

  private

  def initialise_view
    @progress_update = progress_update
    @answers_json = @progress_update.answers_json
    @has_additional_grant_conditions = has_additional_grant_conditions?
    @completion_date = l(salesforce_project_expiry_date(@funding_application), format: '%d %B %Y')
    @cash_contribution_count = get_cash_contribution_count(@funding_application.salesforce_case_id) 
  end

  def has_additional_grant_conditions?
    salesforce_additional_grant_conditions(@funding_application).any?
  end

  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end


end