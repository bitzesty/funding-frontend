class FundingApplication::PaymentRequests::StartController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger
  include PaymentDetailsAndRequestHelper

  def show

    # Grant award information not included in the content anymore
    # consider removing after payments live.

    # grant_award_type = get_grant_award_type(@funding_application)
    # @grant_award = grant_award_type[:grant_award]
    # @grant_award_type = grant_award_type[:grant_award_type]
    # @payment_request_percentage = grant_award_type[:payment_request_percentage]
    # @this_payment_amount = @grant_award * (@payment_request_percentage.to_f / 100)

  end


  def update

    payment_request = get_first_payment_request(@funding_application)

    if payment_request.nil?

        redirect_to :authenticated_root

    else

      # For first payments - ALWAYS ask applicants for bank details.
      # This code may be reinstated for second payments.
      # if existing_bank_details_valid(@funding_application&.payment_details)

      #   redirect_to_are_these_your_bank_details(payment_request)

      # else

        redirect_to_enter_bank_details(payment_request)

      # end

    end

  end


  private

  # At the time of writing, service only does first payment requests
  # This creates and returns a payment request if none exist yet
  # If it finds an unsubmitted payment request, it returns that
  # If if find a submitted payment request - it returns nil

  # @param funding_application [FundingApplication] An instance of a FundingApplication
  # @return PaymentRequest payment_request or nil if a first payment is submitted
  def get_first_payment_request(funding_application)

    if funding_application.payment_requests.empty?

      payment_request = funding_application.payment_requests.create  

    elsif funding_application.payment_requests.first.submitted_on.nil?

      payment_request = funding_application.payment_requests.first   

    else

      payment_request = nil      

    end   

    payment_request

  end


  # Check to see if the existing bank details contain
  # enough information to be considered complete.
  # Simple validation that checks for the presence
  # of the mandatory details.
  # Have not used rails validation as it includes 
  # encryption logic.  
  # During first payments, its likely that any 
  # successfully completed bank details will 
  # proceed directly to payment anyway.
  #
  # @param payment_details [PaymentDetails] An instance of a PaymentDetails
  # @return Boolean true if all the mandatory details are completed
  def existing_bank_details_valid(payment_details)

    if payment_details.present?
    
      payment_details.account_name.present? && 
        payment_details.account_number.present? &&
          payment_details.sort_code.present? &&
            payment_details.evidence_file.present?

    end
  
  end

end
