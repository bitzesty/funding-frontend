class FundingApplication::BankDetails::UploadEvidenceController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger
  include Enums::ArrearsJourneyStatus
  
  def show()

  end

  def update()

    add_file if params.has_key?(:add_file_button)  

    save_and_continue if params.has_key?(:save_and_continue_button)

  end

  # Method responsible for validating  and uploading evidence file
  # and rerendering the page 
  def add_file

    logger.info "Updating evidence_file for payment_details ID: " \
                "#{@funding_application.payment_details.id}"

    @funding_application.payment_details.validate_evidence_file = true
    
    @funding_application.payment_details.update(payment_details_params)

    if @funding_application.payment_details.valid?

      logger.info "Finished updating payments_details ID: " \
                  "#{@funding_application.payment_details.id}"

      redirect_to(:funding_application_bank_details_upload_evidence)
      
    else

      logger.info "Validation failed when attempting to update " \
                  "payments_details ID: #{@funding_application.payment_details.id}"

      log_errors(@funding_application.payment_details)

      render :show

    end

  end


  # Method responsible for validating existence of payment details evidence file
  # before redirecting to the next page in the journey
  def save_and_continue

    @funding_application.payment_details.validate_evidence_file = true

    if @funding_application.payment_details.valid?

      @funding_application.arrears_journey_tracker
        .payment_request
          .answers_json['bank_details_journey']['status'] = JOURNEY_STATUS[:completed]

    @funding_application.arrears_journey_tracker.payment_request.save

      logger.info 'Successfully validated payment details evidence file when '
                  'navigating past payment details confirmation screen for '
                  "payment_details ID: #{@funding_application.payment_details.id}"

      redirect_to(:funding_application_progress_and_spend_progress_and_spend_tasks)

    else

      logger.info 'Validation failed when attempting to navigate past '
                  "payment details evidence uplaod for payment_details ID: #{@funding_application.payment_details.id}"

      log_errors(@funding_application.payment_details)

      render :show

    end

  end

  private

  def payment_details_params

    params.fetch(:payment_details, {}).permit(:evidence_file)

  end

end
