class FundingApplication::ProgressAndSpend::Payments::HighSpendEvidenceController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger
  include ProgressAndSpendHelper
  
    def show()

      payment_request =
        @funding_application.arrears_journey_tracker.payment_request

      @high_spend = payment_request.high_spend.find(params[:high_spend_id])

    end
  
    def update()

      @payment_request =
        @funding_application.arrears_journey_tracker.payment_request

      @high_spend = @payment_request.high_spend.find(params[:high_spend_id])

      add_file if params.has_key?(:add_file_button) 

      save_and_continue if params.has_key?(:save_and_continue_button)

    end

    # adds the evidence of spend file.
    def add_file

      logger.info "Updating evidence_of_spend_file for "\
        "high_spend_id: #{@high_spend.id}"
  
      @high_spend.validate_file = true
      @high_spend.cost_headings = get_headings(@funding_application)
  
      @high_spend.update(high_spend_params(params))
  
      if @high_spend.valid?
  
        logger.info "Finished updating high_spend.id: " \
                    "#{@high_spend.id}"
  
        redirect_to(
          funding_application_progress_and_spend_payments_high_spend_evidence_path(
          high_spend_id: @high_spend.id
          )
        ) 

        return
  
      else
  
        logger.info "Validation failed when adding a file to " \
                    "high_spend.id: #{@high_spend.id}"
  
        log_errors(@high_spend)
  
        render :show and return
  
      end
  
    end

    # continues the journey
    def save_and_continue

      logger.info "Finishing high_spend_id: #{@high_spend.id}"
  
      @high_spend.validate_file = true
      @high_spend.cost_headings = get_headings(@funding_application)
  
      if @high_spend.valid?
  
        redirect_to(
          funding_application_progress_and_spend_payments_high_spend_summary_path
        )

        return
  
      else

        logger.info "Validation failed when finishing high_spend_id: " \
          "#{@high_spend.id}"

        log_errors(@payment_request)
  
        render :show and return
  
      end
  
    end

    private

    # Returns the fetched params.
    # @params [ActionController::Parameters] params A hash of params
    # @return [ActionController::Parameters] params A hash of filtered params
    def high_spend_params(params)
  
      params.fetch(:high_spend, {}).permit(:evidence_of_spend_file)
  
    end

  end
