# answers_json structure upon using this form:
# {
#   "arrears_journey": {
#     "status": 1,
#     "spend_journeys_to_do": [
#       {
#         "spends_under": {
#         "spends_to_do": [],
#         "spend_threshold": 250
#         }
#       }
#     ]
#   }
# }

class FundingApplication::ProgressAndSpend::Payments::LowSpendAddController < ApplicationController
  include FundingApplicationContext
  
    def show()

    end
  
    def update()

      payment_request = 
        @funding_application.arrears_journey_tracker.payment_request

    end

  end
