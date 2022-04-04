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
  @non_cash_contribution = 
    @funding_application.arrears_journey_tracker.progress_update.\
      progress_update_non_cash_contribution.find(params[:non_cash_contribution_id])
  end
end