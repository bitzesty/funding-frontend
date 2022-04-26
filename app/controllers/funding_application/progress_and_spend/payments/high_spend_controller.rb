class FundingApplication::ProgressAndSpend::Payments::HighSpendController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  
    def show()
    end
  
    def update()

      remove_spend_journey_from_todo_array(
        @funding_application.arrears_journey_tracker.payment_request
      )

      spend_journey_redirector(@funding_application.arrears_journey_tracker.\
          payment_request.answers_json)

    end

  end
