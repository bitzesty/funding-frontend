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

      initialise_instance_vars

    end
  
    def update()

      payment_request =
        @funding_application.arrears_journey_tracker.payment_request

      payment_request.validate_add_another_low_spend = true

      payment_request.update(fetched_params(params))

      unless payment_request.errors.any?

        if payment_request.add_another_low_spend.to_s == 'false'

          redirect_to(
            funding_application_progress_and_spend_payments_table_of_spend_path
          )

       elsif payment_request.add_another_low_spend.to_s == 'true'

          redirect_to(
            funding_application_progress_and_spend_payments_low_spend_select_path
          )

       end

      else

        initialise_instance_vars

        render :show

      end

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

    private

    # Returns the fetched params.
    # @params [ActionController::Parameters] params A hash of params
    # @return [ActionController::Parameters] params A hash of filtered params
    def fetched_params(params)
      params.fetch(:payment_request, {}).permit(
        :add_another_low_spend
      )
    end

    def initialise_instance_vars

      payment_request =
        @funding_application.arrears_journey_tracker.payment_request

      @spend_threshold = get_low_spend_threshold_from_json(payment_request, @funding_application)
      
      @low_spend = payment_request.low_spend

      @low_spend_update_total = @low_spend.sum {|ls| ls.total_amount + ls.vat_amount}

      @low_spend_table_heading =
      t(
        'progress_and_spend.payments.low_spend_summary.your_project_spend',
        spend_amount: @spend_threshold
      )

      @show_change_links = true

    end

  end
