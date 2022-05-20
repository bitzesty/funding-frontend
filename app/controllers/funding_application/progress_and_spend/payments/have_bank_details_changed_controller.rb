class FundingApplication::ProgressAndSpend::Payments::HaveBankDetailsChangedController < ApplicationController
  include FundingApplicationContext
  include Enums::ArrearsJourneyStatus
  include ProgressAndSpendHelper

  def show

    @payment_request =
      @funding_application.arrears_journey_tracker.payment_request

    if ask_if_bank_account_changed?(@funding_application)

      initialise_view

    else
      # Setup JSON and skip straight to asking
      @payment_request.\
        answers_json['bank_details_journey']['has_bank_details_update'] = true

      @payment_request.\
        answers_json['bank_details_journey']['status'] = \
          JOURNEY_STATUS[:in_progress]

      @payment_request.save

      redirect_to(
        funding_application_bank_details_enter_path
      )

    end

  end

  def update

    @payment_request =
      @funding_application.arrears_journey_tracker.payment_request

    @payment_request.has_bank_details_update = 
      params[:payment_request].nil? ? nil : \
        params[:payment_request][:has_bank_details_update]

    @payment_request.validate_has_bank_details_update = true

    if @payment_request.valid?
          
      answers_json = @payment_request.answers_json
      answers_json['bank_details_journey']['has_bank_details_update'] = 
        @payment_request.has_bank_details_update

      if @payment_request.has_bank_details_update == "true" 
        answers_json['bank_details_journey']['status'] = JOURNEY_STATUS[:in_progress] 
        @payment_request.save
        redirect_to(
          funding_application_bank_details_enter_path
        )
      else
        answers_json['bank_details_journey']['status'] = JOURNEY_STATUS[:completed]
        @payment_request.save
        redirect_to \
          funding_application_progress_and_spend_progress_and_spend_tasks_path
      end

    else
      render :show
    end

  end

  private

  def initialise_view
    @payment_request.has_bank_details_update = 
      @payment_request.answers_json['bank_details_journey']['has_bank_details_update'] 
  end


end
