class FundingApplication::ProgressAndSpend::PreviousSubmissions::SubmissionSummary::ProgressUpdateSubmissionController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
 
  def show
    initialise_view
  end

  def update
    redirect_to funding_application_progress_and_spend_previous_submissions_previously_submitted_path(
      completed_arrears_journey_id: params[:completed_arrears_journey_id] )
  end

  private 
  
  def initialise_view
    @progress_update =  @funding_application
      .progress_updates.find(params[:progress_update_id])
    @answers_json = @progress_update.answers_json
    @has_additional_grant_conditions = has_additional_grant_conditions?
    @completion_date = l(salesforce_project_expiry_date(@funding_application), format: '%d %B %Y')
    @cash_contribution_count = 
      get_cash_contribution_count(@funding_application.salesforce_case_id) 
  end

  def has_additional_grant_conditions?
    salesforce_additional_grant_conditions(@funding_application).any?
  end

end
