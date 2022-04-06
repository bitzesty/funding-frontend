class FundingApplication::ProgressAndSpend::ProgressUpdate::\
  CashContribution::CashContributionNowController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()
    @cash_contribution =
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_cash_contribution.find(params[:cash_contribution_id])
  end 

  def update()

    @cash_contribution =
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_cash_contribution.find(params[:cash_contribution_id])

    rp = required_params(params)

    @cash_contribution.validate_received_amount_expected = true

    @cash_contribution.validate_amount_received_so_far = \
      rp[:received_amount_expected] == 'false'

    @cash_contribution.update(rp)

    unless @cash_contribution.errors.any?

      if @cash_contribution.received_amount_expected

        set_cash_contribution_update_as_finished(
          @funding_application.arrears_journey_tracker.progress_update,
          @cash_contribution.salesforce_project_income_id
        )

        medium_cash_contribution_redirector(
          @funding_application.\
            arrears_journey_tracker.progress_update.answers_json
        )

      else

        redirect_to(
          funding_application_progress_and_spend_progress_update_cash_contribution_cash_contribution_future_path(
              progress_update_id:
                @funding_application.arrears_journey_tracker.progress_update.id,
              cash_contribution_id:  @cash_contribution.id
  
          )
        )

      end

    else

      render :show

    end
 
  end

  # Returns the required params
  #
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def required_params(params)
    params.require('progress_update_cash_contribution').permit(
      :received_amount_expected,
      :amount_received_so_far
    )
  end

end
