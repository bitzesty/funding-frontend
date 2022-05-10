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
# 
class FundingApplication::ProgressAndSpend::Payments::LowSpendSummaryController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  
    def show()

      payment_request =
        @funding_application.arrears_journey_tracker.payment_request

      @spend_amount = get_low_spend_threshold_from_json(payment_request)
      
      @low_spend = payment_request.low_spend

      @update_total = @low_spend.sum {|ls| ls.total_amount + ls.vat_amount}

    end
  
    def update()

      redirect_to(
        funding_application_progress_and_spend_payments_table_of_spend_path
        )

    end

    def delete()

      logger.info(
        'Deleting low_spend with id: ' \
          "#{params[:low_spend_id]} from payment_request ID: " \
            "#{params[:payment_request_id]}"
      )

      LowSpend.destroy(params[:low_spend_id])

      redirect_to(
        funding_application_progress_and_spend_payments_low_spend_summary_path
        )

    end

  end
