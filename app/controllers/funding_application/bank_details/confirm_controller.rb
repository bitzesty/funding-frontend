class FundingApplication::BankDetails::ConfirmController < ApplicationController
    include FundingApplicationContext
    include ObjectErrorsLogger

  def update

    logger.info 'User has confirmed payment details on confirmation screen '
                "for payment_details ID: #{@funding_application.payment_details.id}"

    redirect_to(:funding_application_bank_details_upload_evidence)

  end

end
