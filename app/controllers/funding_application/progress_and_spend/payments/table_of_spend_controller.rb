class FundingApplication::ProgressAndSpend::Payments::TableOfSpendController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger
  include ProgressAndSpendHelper
  
    def show()

      @payment_request = @funding_application.arrears_journey_tracker.payment_request

    end
  
    def update()

      add_file if params.has_key?(:add_file_button) 

      save_and_continue if params.has_key?(:save_and_continue_button)

    end

    # adds the table of spend file
    def add_file

      @payment_request = @funding_application.arrears_journey_tracker.payment_request

      logger.info "Updating table_of_spend_file for "\
        "payment_request id: #{@payment_request.id}"
  
      @payment_request.validate_table_of_spend_file = true
  
      @payment_request.update(payment_details_params(params))
  
      if @payment_request.valid?
  
        logger.info "Finished updating payment request ID: " \
                    "#{@payment_request.id}"
  
        redirect_to(:funding_application_progress_and_spend_payments_table_of_spend)
  
      else
  
        logger.info "Validation failed when attempting to update " \
                    "payments_request ID: #{@payment_request.id}"
  
        log_errors(@payment_request)
  
        render :show
  
      end
  
    end

    # continues the journey
    def save_and_continue

      @payment_request = @funding_application.arrears_journey_tracker.payment_request

      @payment_request.validate_table_of_spend_file = true
  
      if @payment_request.valid?
  
      remove_spend_journey_from_todo_array(
        @funding_application.arrears_journey_tracker.payment_request
      )
      spend_journey_redirector(@funding_application.arrears_journey_tracker.\
          payment_request.answers_json)
  
      else

        logger.info "Validation failed when attempting to add a table of " \
          "spend to payment request ID: "\
            "#{@payment_request.id}"
  
        log_errors(@payment_request)
  
        render :show
  
      end
  
    end

    private

    # Returns the fetched params.
    # @params [ActionController::Parameters] params A hash of params
    # @return [ActionController::Parameters] params A hash of filtered params
    def payment_details_params(params)
  
      params.fetch(:payment_request, {}).permit(:table_of_spend_file)
  
    end

  end
