class FundingApplication::ProgressAndSpend::Payments::HighSpendAddController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  
    def show()

      payment_request =
        @funding_application.arrears_journey_tracker.payment_request

      @spend_threshold = get_high_spend_threshold_from_json(payment_request, @funding_application)
      
      @headings = get_headings(@funding_application)

      @high_spend = payment_request.high_spend.build

    end
  
    def update()

      payment_request =
        @funding_application.arrears_journey_tracker.payment_request

      @high_spend = payment_request.high_spend.build

      high_spend_add_edit_controller_update_helper(
        @high_spend,
        payment_request,
        @funding_application,
        params
      )

    end

  end
