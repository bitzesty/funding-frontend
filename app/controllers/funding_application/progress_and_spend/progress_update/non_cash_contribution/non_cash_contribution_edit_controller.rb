class FundingApplication::ProgressAndSpend::ProgressUpdate::\
  NonCashContribution::NonCashContributionEditController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper


  def show()
    get_non_cash_contribution
  end

  def update()
    get_non_cash_contribution

    update_validate_redirect_non_cash_contribution(@non_cash_contribution, @funding_application)

  end

  private

  def get_non_cash_contribution()
    begin
      @non_cash_contribution = 
        @funding_application.arrears_journey_tracker.progress_update.\
          progress_update_non_cash_contribution.find(params[:non_cash_contribution_id])
    rescue ActiveRecord::RecordNotFound  
      redirect_to(
        funding_application_progress_and_spend_progress_update_non_cash_contribution_non_cash_contribution_summary_path(
            progress_update_id:
              @funding_application.arrears_journey_tracker.progress_update.id
        )
      )
      return
    end
  end
end