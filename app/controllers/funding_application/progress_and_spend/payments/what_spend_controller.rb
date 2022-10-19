class FundingApplication::ProgressAndSpend::Payments::WhatSpendController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  
  def show()

    @spend_threshold = get_spend_threshold(@funding_application)

  end

  def update()

    payment_request =
      @funding_application.arrears_journey_tracker.payment_request

      if @funding_application.m1_40_payment_can_start? ||
        @funding_application.dev_40_payment_can_start?

        payment_request.validate_spend_journeys_to_do_40_perc = true
      else
        payment_request.validate_spend_journeys_to_do = true
      end

    payment_request.update(required_params(params))

    unless payment_request.errors.any?

      update_json(
        payment_request,
        get_spend_threshold(@funding_application)
      )

      remove_high_spends_with_no_file(payment_request) if \
        payment_request.high_spend.present?

      spend_journey_redirector(
        payment_request.answers_json,
        payment_request.high_spend.present?,
        payment_request.low_spend.present?
      )

    else

      @spend_threshold = get_spend_threshold(@funding_application)
      render :show

    end

  end

  private

  # Returns the required params
  #
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def required_params(params)
    params.require(:payment_request).permit(
      :higher_spend, :lower_spend, :no_update
    )
  end

  # Updates json with spend journeys that the user intends to complete
  # based on the params from the completed page.
  #
  # @params [PaymentRequest] payment_request
  # @params [Integer] spend_threshold E.g £250 for medium, £500 for large
  def update_json(payment_request, spend_threshold)

    selected_array = []

    selected_array.append(
      {spends_over: {
        spend_threshold: spend_threshold,
        cost_headings: []
        }
      }
    ) if payment_request.higher_spend == 'true'

    selected_array.append(
      {spends_under: {
        spend_threshold: spend_threshold,
        spends_to_do: []
        }
      }
    ) if payment_request.lower_spend == 'true'

    payment_request.answers_json['arrears_journey']\
      ['spend_journeys_to_do'] = selected_array

    payment_request.save

  end

end
