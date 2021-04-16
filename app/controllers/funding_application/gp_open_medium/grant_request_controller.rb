class FundingApplication::GpOpenMedium::GrantRequestController < ApplicationController
  include FundingApplicationContext

  # This method sets instance variables used when rendering the :show template
  def show

    @total_project_cost = helpers.calculate_total(
      @funding_application.project_costs
    ).to_i

    @total_cash_contributions = helpers.calculate_total(
      @funding_application.cash_contributions
    ).to_i

    @final_grant_amount = @total_project_cost - @total_cash_contributions

    @minimum_request_value = 10000.to_i
    @maximum_request_value = 250000.to_i

    @costs_greater_than_contributions = @final_grant_amount.positive?

    @grant_request_less_than_funding_band = @final_grant_amount <=
      @maximum_request_value

    @grant_request_more_than_minimum =
      @final_grant_amount >= @minimum_request_value

    @grant_request_is_valid = @costs_greater_than_contributions &&
        @grant_request_less_than_funding_band &&
        @grant_request_more_than_minimum

  end

end
