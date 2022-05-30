# answers_json structure upon using this form:
# {
#   "arrears_journey": {
#     "status": 1,
#     "spend_journeys_to_do": [
#       {
#         "spends_under": {
#         "spends_to_do": ["a spend selected for update", "another spend"],
#         "spend_threshold": 250
#         }
#       }
#     ]
#   }
# }

class FundingApplication::ProgressAndSpend::Payments::LowSpendAddController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  
  def show()

    payment_request =
      @funding_application.arrears_journey_tracker.payment_request

    headings = get_spend_headings_list(payment_request)

    unless headings.empty?

      # always take the first heading in the list
      @heading = headings.first
      @spend_threshold = get_low_spend_threshold_from_json(payment_request, @funding_application)
      @low_spend = get_low_spend(@funding_application, @heading)

    else

      redirect_to(
        funding_application_progress_and_spend_payments_low_spend_summary_path)

    end

  end

  # Operates on the basis that the first heading when :show
  # was called is still the first heading now.
  def update()

    payment_request =
      @funding_application.arrears_journey_tracker.payment_request

    # always take the first heading in the list
    headings = get_spend_headings_list(payment_request)
    @heading = headings.first
    @spend_threshold = get_low_spend_threshold_from_json(payment_request, @funding_application)
    @low_spend = get_low_spend(@funding_application, @heading)

    @low_spend.validate_vat_amount = true
    @low_spend.validate_total_amount = true

    @low_spend.update(required_params(params))

    unless @low_spend.errors.any?

      @low_spend.cost_heading = @heading
      @low_spend.spend_threshold = @spend_threshold
      @low_spend.save!

      remove_heading_from_to_do(payment_request)

      if to_do_list_empty?(payment_request)
        redirect_to(
          funding_application_progress_and_spend_payments_low_spend_summary_path)
      else
        # Redirect to same page to pick up next cost type
        redirect_to(
          funding_application_progress_and_spend_payments_low_spend_add_path)
      end

    else

      render :show

    end

  end

  private

  # Gets spends_to_do from answers_json as the spend_headings_list
  # this is the basis for a to do list for the low spend arrears
  # payments journey.
  # Once a low spend journey is completed for that cost heading - that
  # cost heading will be removed from the array.
  #
  # If applicants use the browser arrows to drive the journey backwards and
  # forward, then JSON in the spend journey can become invalid.
  # To avoid showing a user a rails error, log and redirect the user back to
  # the spend-so-far page, which is a safe place to return to any aspect of
  # the spend journey.
  #
  # @param [PaymentRequest] payment_request PaymentRequest instance that
  #                                         the array is recorded against
  # @return [Array] spend_headings_list
  def get_spend_headings_list(payment_request)

    begin

      # The first journey in [spend_journeys_to_do],
      # will always be the journey we are in.
      payment_request.answers_json['arrears_journey']['spend_journeys_to_do'].\
        first['spends_under']['spends_to_do']

    rescue

      Rails.logger.info("Exception in get_spend_headings_list for " \
        "funding application #{@funding_application.id}. Redirecting to " \
          "spend-so-far path.")

      redirect_to \
        funding_application_progress_and_spend_payments_spend_so_far_path()

    end

  end

  # Gets an instance of LowSpend.
  # Returns existing instance, if it finds one with a matching heading.
  # Otherwise builds an in memory instance and returns.
  # @param [FundingApplication] funding_application
  # @param [String] heading A cost heading 
  # @return [LowSpend] persisted or in memory instance
  def get_low_spend(funding_application, heading)

    payment_request =
      @funding_application.arrears_journey_tracker.payment_request

    low_spend = payment_request.low_spend.find_by(cost_heading: heading)

    low_spend.nil? ? \
      payment_request.low_spend.build : \
        low_spend

  end

  private

  # Returns the required params.
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def required_params(params)
    params.require(:low_spend).permit(
      :total_amount,
      :vat_amount
    )
  end

  # Removes first item in to do array, so that it will not be revisited
  # unless selected by the user again.
  #
  # @param [PaymentRequest] payment_request
  def remove_heading_from_to_do(payment_request)

    begin

      payment_request.answers_json['arrears_journey']['spend_journeys_to_do'].\
        first['spends_under']['spends_to_do'].shift

      payment_request.save!

    rescue

      # In the event of an error - do nothing
      Rails.logger.info("Exception in remove_heading_from_to_do for " \
        "funding application #{@funding_application.id}.")

    end

  end

  # Returns true if the spends_to_do array is empty
  #
  # @param [PaymentRequest] payment_request
  # @return [Boolean] true if the to do array is empty
  def to_do_list_empty?(payment_request)

    begin

      payment_request.answers_json['arrears_journey']['spend_journeys_to_do'].\
        first['spends_under']['spends_to_do'].empty?

    rescue

      # In the event of an error - continue journey as though completed
      Rails.logger.info("Exception in to_do_list_empty? for " \
        "funding application #{@funding_application.id}.")

      true

    end

  end

end
