class FundingApplication::ProgressAndSpend::Payments::HighSpendEditController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  
    def show()

      payment_request =
        @funding_application.arrears_journey_tracker.payment_request

      @spend_threshold = get_high_spend_threshold_from_json(payment_request)

      @headings = get_headings(@funding_application)

      @high_spend = payment_request.high_spend.find(params[:high_spend_id])

      populate_day_month_year(@high_spend)

    end
  
    def update()

      payment_request =
        @funding_application.arrears_journey_tracker.payment_request

      @high_spend = payment_request.high_spend.find(params[:high_spend_id])

      high_spend_add_edit_controller_update_helper(
        @high_spend,
        payment_request,
        @funding_application,
        params
      )

    end

  end
