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
# spends_to_do will be populated and used to track how many times view
# is shown.
class FundingApplication::ProgressAndSpend::Payments::\
    LowSpendSelectController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()
    populate_form_attributes_from_salesforce
  end

  def update()

    payment_request =
      @funding_application.arrears_journey_tracker.payment_request

    @headings = get_salesforce_cost_headings(@funding_application) \
      unless @headings.present?

    rp = required_params(
      params,
      @headings
    )

    selected_array = []
    rp.each do |heading, selected|
      selected_array.push(heading) if selected == 'true'
    end

    payment_request.validate_lower_spend_chosen = true
    payment_request.lower_spend_chosen = selected_array.present?

    if payment_request.valid?

        # replace all costs heading so that only selected headings are kept
      update_spend_headings_list(
        selected_array,
        payment_request
      )

      redirect_to \
        funding_application_progress_and_spend_payments_low_spend_add_path()

    else

      @spend_amount = get_spend_threshold_from_json(payment_request)

      # error link id, if the applicant selects nothing.
      @first_form_element = 
        "payment_request_#{@headings.first}"

      render :show

    end

  end

  private

  # Gets the form information from Salesforce and populates these variables for
  # use on the form:
  # @headings - all the cost headings selected by an applicant with their application
  # @first_form_element - if nothing is selected, form error href goes to this id
  #
  # Also initialises answers_json with all cost/spend headings. These are used to
  # check permitted params when posting to this form.
  # Headings not selected for update will be removed in the update method.
  #
  # Needs enhancement for large applications.
  #
  # Salesforce called each time.  Refactor if too slow.
  #
  # Consider passing in pointers if tricky to unit test.
  #
  def populate_form_attributes_from_salesforce

    payment_request =
      @funding_application.arrears_journey_tracker.payment_request

    @headings = get_salesforce_cost_headings(
      @funding_application
    )

    update_spend_headings_list(
      @headings,
      payment_request
    )

    @spend_amount = get_spend_threshold_from_json(payment_request)

    # error link id, if the applicant selects nothing.
    @first_form_element =
      "payment_request_#{@headings.first}"

  end

  # Updates answers_json so that the cost_headings_array can be the basis
  # for a to do list for the low spend arrears payments journey.
  # Once a low spend journey is completed for that cost/spend heading - that
  # cost heading will be removed from the array.
  #
  # @param [Array] headings An array of cost headings
  # @param [PaymentRequest] payment_request PaymentRequest instance that
  #                                         the array is recorded against
  def update_spend_headings_list(headings, payment_request)

    # The first journey in [spend_journeys_to_do],
    # will always be the journey we are in.
    payment_request.answers_json['arrears_journey']['spend_journeys_to_do'].\
      first['spends_under']['spends_to_do'] = headings

    payment_request.save!

  end

  # Returns the required params.  Uses @headings to check that a user
  # is not passing back headings not in the original list
  #
  # @params [Array] headings An array of cost headings
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def required_params(params, headings)
    params.require(:payment_request).permit(
      headings.map {|heading| heading.to_sym}
    )
  end

end
