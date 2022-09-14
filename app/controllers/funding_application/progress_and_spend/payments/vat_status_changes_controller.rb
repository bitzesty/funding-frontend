# This controller amends the vat_status key with answers_json.  Example below:
#
# {
# 	"arrears_journey": {
# 		"status": 1,
# 		"vat_status": {
# 			"changed": "true",
# 			"vat_number": "1212121212",
# 			"vat_registered_in_salesforce": false
# 		},
# 		"spend_journeys_to_do": [{
# 			"spends_over": {
# 				"cost_headings": ["New staff", "Equipment", "Travel"],
# 				"spend_threshold": 250
# 			}
# 		}]
# 	},
# 	"bank_details_journey": {
# 		"status": 0,
# 		"has_bank_details_update": null
# 	}
# }

class FundingApplication::ProgressAndSpend::Payments::VatStatusChangesController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  # Gets the current payment request, and populates attr_accessors for
  # the payment request using answers from any earlier run through of
  # the journey.
  #
  # @vat_registered is populated from Salesforce.
  def show()

    @payment_request =
      @funding_application.arrears_journey_tracker.payment_request

    if @payment_request.answers_json['arrears_journey'].key?('vat_status')

      @payment_request.vat_status_changed =
        @payment_request.answers_json['arrears_journey']\
          ['vat_status']['changed']

      @payment_request.vat_number =
        @payment_request.answers_json['arrears_journey']\
          ['vat_status']['vat_number'] if
            @payment_request.answers_json['arrears_journey']\
              ['vat_status'].key?('vat_number')

    end

    @vat_registered =
      vat_registered?(@funding_application.organisation.salesforce_account_id)

  end

  # Gets @vat_registered from Salesforce. And only validates for a
  # vat_number if the grantee indicates the organisation is VAT registered
  # now, when it wasn't VAT registered before.
  def update()

    @vat_registered =
      vat_registered?(@funding_application.organisation.salesforce_account_id)

    @payment_request =
      @funding_application.arrears_journey_tracker.payment_request

    # assign params to payment request
    @payment_request.update(payment_details_params(params))

    # toggle validation
    @payment_request.validate_vat_status_changed = true
    @payment_request.validate_vat_number =
      (@payment_request.vat_status_changed == "true" && !@vat_registered)

    if @payment_request.valid?

      # save to answers_json and redirect
      vat_changed_hash =
        {'vat_status': {'changed': @payment_request.vat_status_changed}}

      vat_changed_hash[:vat_status]['vat_number'] =
        @payment_request.vat_number if @payment_request.vat_number.present?

      vat_changed_hash[:vat_status]['vat_registered_in_salesforce'] = @vat_registered

      @payment_request.\
        answers_json['arrears_journey']['vat_status'] =
          vat_changed_hash[:vat_status]

      @payment_request.save

      redirect_to funding_application_progress_and_spend_payments_spend_so_far_path(
        payment_request_id:
          @funding_application.arrears_journey_tracker.payment_request_id
      )

    else

      render :show

    end

  end

  private

  # Returns the fetched params.
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def payment_details_params(params)

    params.fetch(:payment_request, {}).permit(
      :vat_status_changed,
      :vat_number
    )

  end

end
