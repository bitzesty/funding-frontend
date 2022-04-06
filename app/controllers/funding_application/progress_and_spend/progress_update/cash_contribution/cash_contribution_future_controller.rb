class FundingApplication::ProgressAndSpend::ProgressUpdate::\
  CashContribution::CashContributionFutureController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()
    @cash_contribution =
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_cash_contribution.find(params[:cash_contribution_id])

    populate_day_month_year(@cash_contribution)
  end 

  def update()

    @cash_contribution =
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_cash_contribution.find(params[:cash_contribution_id])

    validate_and_assign_date_params(@cash_contribution, params)

    @cash_contribution.validate_will_receive_amount_expected = true

    @cash_contribution.validate_reason_amount_expected_not_received = \
      required_params(params)[:will_receive_amount_expected] == 'false'

    @cash_contribution.update(required_params(params))

    unless @cash_contribution.errors.any?

      set_cash_contribution_update_as_finished(
        @funding_application.arrears_journey_tracker.progress_update,
        @cash_contribution.salesforce_project_income_id
      )

      medium_cash_contribution_redirector(
        @funding_application.\
          arrears_journey_tracker.progress_update.answers_json
      )

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
      :will_receive_amount_expected,
      :reason_amount_expected_not_received,
      :date_amount_received,
      :date_day,
      :date_month,
      :date_year
    )
  end

  # Gets the day, month, year params and populates model with them
  # Uses model validation to see if the supplied info makes a valid date
  # If supplied info valid, create a date object from it
  # then include that date in the supplied params for later update.
  #
  # @params [ProgressUpdateCashContribution] cash_contribution
  # @params [ActionController::Parameters] params unfiltered params
  def validate_and_assign_date_params(cash_contribution, params)

    rp = required_params(params)

    if rp[:will_receive_amount_expected] == 'true'

      cash_contribution.validate_date_day_month_year = true

      cash_contribution.date_day = rp[:date_day].to_i
      cash_contribution.date_month = rp[:date_month].to_i
      cash_contribution.date_year = rp[:date_year].to_i

      if cash_contribution.valid?

        params[:progress_update_cash_contribution][:date_amount_received] = DateTime.new(
          cash_contribution.date_year,
          cash_contribution.date_month,
          cash_contribution.date_day
        )

      end

    end

  end

  # Allows returning applicants to see the date they added first time
  # Parses date, if found, and populates day, month, year fields
  #
  # @param [ProgressUpdateCashContribution] cash_contribution
  def populate_day_month_year(cash_contribution)

    date_amount_received = cash_contribution&.date_amount_received

    if date_amount_received.present?
      cash_contribution.date_day = date_amount_received.day
      cash_contribution.date_month = date_amount_received.month
      cash_contribution.date_year = date_amount_received.year
    end

  end

end
