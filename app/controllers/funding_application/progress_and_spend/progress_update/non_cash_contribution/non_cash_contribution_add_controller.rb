class FundingApplication::ProgressAndSpend::ProgressUpdate::\
  NonCashContribution::NonCashContributionAddController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()
    @non_cash_contribution = 
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_non_cash_contribution.build
  end

  def update()

    @non_cash_contribution = 
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_non_cash_contribution.build

    update_validate_redirect_non_cash_contribution(@non_cash_contribution, @funding_application)

  end
end