module PaymentDetailsAndRequestHelper
  include SalesforceApi

  # Helper method to redirect a user to the 'are these your bank details' route
  #
  # @param payment_request [PaymentRequest] An instance of a PaymentRequest
  def redirect_to_are_these_your_bank_details(payment_request)

    logger.info('Redirecting to the "are these your bank details" page')

    redirect_to(
      funding_application_payment_request_have_your_bank_details_changed_path(
        payment_request_id: payment_request.id
      )
    )

  end

  # Helper method to redirect a user to the 'enter bank details' route
  #
  # @param payment_request [PaymentRequest] An instance of a PaymentRequest
  def redirect_to_enter_bank_details(payment_request)

    logger.info('Redirecting to the enter bank details page')

    redirect_to(
      funding_application_payment_request_bank_details_path(
        payment_request_id: payment_request.id
      )
    )

  end

  # Helper method to orchestrate redirection and submission during the flow
  # of a payment request journey, based on the total grant awarded to a 
  # specified funding application and the amount of payments made
  #
  # @param funding_application [FundingApplication] An instance of a FundingApplication
  # @param payment_request [PaymentRequest] An instance of a PaymentRequest
  def orchestrate_redirect_or_submission(funding_application, payment_request)
  
    payment_related_details = retrieve_payment_related_details(funding_application)

    grant_award = payment_related_details[:grant_award]

    if grant_award > 0 && grant_award <= 10000

      logger.info(
        "Payment request triggered for funding_application ID: #{funding_application.id}" \
        ', grant award is between £0 and £10,000'
      )

      update_payment_request_amount(payment_request, grant_award)

      submit_payment_request(funding_application, payment_request)

    elsif grant_award > 10000 && grant_award <= 100000

      logger.info(
        "Payment request triggered for funding_application ID: #{funding_application.id}" \
        ', grant award is between £10,000.01 and £100,000'
      )

      calculate_payment_request_between_10000_and_100000(funding_application, payment_request, grant_award)

      submit_payment_request(funding_application, payment_request)

    else

      logger.info(
        "Payment request triggered for funding_application ID: #{funding_application.id}" \
        ', grant award is above £100,000'
      )

      redirect_to_evidence_of_spend

    end

  end

  # keep logic to decide grant award logic in one place.  Used to determine the flow
  # of the payment journey and determine what content is shown on the payment submitted form.

  # @param funding_application [FundingApplication] An instance of a FundingApplication
  # @return String Describing the payment type scenario: 
  # TODO - change to enum or class.
  # TODO - change the above function to use this function and logic rather than replicate logic
  def get_grant_award_type(funding_application)

    payment_related_details = retrieve_payment_related_details(funding_application)

    grant_award = payment_related_details[:grant_award]

    case
    when grant_award > 0 && grant_award <= 10000
      {
        grant_award: grant_award,
        grant_award_type: 'grant_award_under_10000',
        payment_request_percentage: 100
      }
    when grant_award > 10000 && grant_award <= 100000
      {
        grant_award: grant_award,
        grant_award_type: 'grant_award_between_10000_and_100000',
        payment_request_percentage: 50
      }
    when grant_award > 100000
      {
        grant_award: grant_award,
        grant_award_type: 'grant_award_over_100000',
        payment_request_percentage: payment_related_details[:grant_percentage].to_f / 100.to_f
      } 
    end

  end

  # Helper method to redirect a user to the evidence of spend' route
  def redirect_to_evidence_of_spend

    logger.info('Redirecting to the evidence of spend page(s)')

    redirect_to(
      :funding_application_payment_request_review_your_project_spend
    )

  end

  # Helper method to retrieve payment-related details for a given funding application
  #
  # @param funding_application [FundingApplication] An instance of a FundingApplication
  # @return Hash payemnt_details A hash in the following format:
  # {
  #   'grant_award': 100001,
  #   'grant_percentage': 100
  # }

  def retrieve_payment_related_details(funding_application)

    salesforce_api_client = SalesforceApiClient.new

    if funding_application.project.present?
      payment_details = salesforce_api_client.get_payment_related_details(funding_application.project.id)
    end

    if funding_application.open_medium.present?
      payment_details = salesforce_api_client.get_payment_related_details(funding_application.id)
    end

    payment_details

  end

  # Helper method to retrieve agreed project costs for a given funding application
  #
  # @param funding_application [FundingApplication] An instance of a FundingApplication
  #
  # @return [RestforceCollection] An instance of a RestforceCollection
  def retrieve_agreed_project_costs(funding_application)

    salesforce_api_client = SalesforceApiClient.new

    if funding_application.project.present?
      salesforce_api_client.get_agreed_project_costs(funding_application.project.id)
    end

    if funding_application.open_medium.present?
      salesforce_api_client.get_agreed_project_costs(funding_application.open_medium.id)
    end

  end

  # Helper method to calculate the total of agreed project costs for a funding application
  #
  # @param agreed_project_costs [AgreedProjectCosts] An instance of a RestforceCollection
  #
  # @return [Float] The calculated total of agreed project costs
  def calculate_agreed_project_costs_total(agreed_project_costs)

    total = 0

    agreed_project_costs.each do |cost|

      # expr0 is the aggregated expression retrieved from Salesforce
      total += cost[:expr0]

    end

    total

  end

  # Orchestrates submitting a payment request
  # Calls store_payment_request_state_when_submitted for support, in the
  # event that the Restforce call fails, this JSON can be looked at.
  # Creates a SalesforceApiClient and uses to call upsert_payment_records.
  # If no Exceptions raised, the payment_request will be marked as submitted 
  # and the json stored by store_payment_request_state_when_submitted removed.
  # Finally, delete the bank details.  These only remain in Salesforce.
  #
  # @param [FundingApplication] funding_application An FundingApplication instance
  # @param [PaymentRequest] payment_request A PaymentRequest instance
  def submit_payment_request(funding_application, payment_request)

    logger.info("Attempting to submit payment_request id: #{payment_request.id} for funding_application id: #{funding_application.id}")
 
    store_payment_request_state_when_submitted(funding_application, payment_request)

    # When time, consider if the client instantiated from retrieve_payment_related_details
    # could be returned and fed into this function.  Fewer SF sessions.
    salesforce_api_client = SalesforceApiClient.new
    salesforce_api_client.upsert_payment_records(funding_application, payment_request)

    payment_request.submitted_on = Time.now
    payment_request.payload_submitted = nil
    payment_request.save

    funding_application.payment_details.delete

    logger.info("Payment_request id: #{payment_request.id} submitted for funding_application id: #{funding_application.id}")

    redirect_to(
      funding_application_payment_request_submitted_path(
        payment_request_id: payment_request.id
      )
    )

  end

  # Helper method to retrieve the count of payment requests against a funding application
  #
  # @param funding_application [FundingApplication] An instance of a FundingApplication
  def get_payment_request_count(funding_application)

    logger.debug(
      "Retrieving count of submitted payment requests for funding_application ID: #{funding_application.id}"
    )

    funding_application.payment_requests.count

  end

  # Helper method to update the amount_requested value of a given payment_request
  #
  # @param payment_request [PaymentRequest] An instance of a PaymentRequest
  # @param amount [Float] The value to set as the PaymentRequest.amount_requested attribute
  def update_payment_request_amount(payment_request, amount)

    # TODO: Add validation
    payment_request.update(amount_requested: amount)

  end

  # Helper method to calculate the payment request value for a funding application with a total
  # grant award between £10,000.01 and £100,000
  #
  # @param funding_application [FundingApplication] An instance of a FundingApplication
  # @param payment_request [PaymentRequest] An instance of a PaymentRequest
  # @param grant_award [Float] The total grant awarded to the specified funding_application
  def calculate_payment_request_between_10000_and_100000(funding_application, payment_request, grant_award)

    count = get_payment_request_count(funding_application)

    if count == 1

      payment_request_amount = grant_award / 2.to_f

      update_payment_request_amount(payment_request, payment_request_amount)

    else

      logger.error("Second payment attempted for funding_application id: #{funding_application.id}")

      # TODO: Make sure 500 page is displayed (problem lies with JS on adding bank-details evidence view)
      raise StandardError.new(
        "Second payment attempted for funding_application id: #{funding_application.id}"
      )

    end

  end

  # Helper method to calculate the payment request value for a funding application with a total
  # grant award over £100,000
  #
  # @param payment_request [PaymentRequest] An instance of a PaymentRequest
  # @param grant_percentage [Float] The grant_percentage used to calculate the payment request amount
  def calculate_payment_request_over_100000(payment_request, grant_percentage)

    total_spend_evidenced = payment_request.spends.sum(:gross_amount)

    payment_request_amount = total_spend_evidenced * (grant_percentage.to_f / 100.to_f)

    update_payment_request_amount(payment_request, payment_request_amount)

  end

  private

  # Stores a encrypted version of the state of payment_request and payment_details
  # at the point that it is sent to Salesforce.   Intended for support should
  # the submission fail.
  #
  # @param [FundingApplication] funding_application An FundingApplication instance
  # @param [PaymentRequest] payment_request A PaymentRequest instance
  def store_payment_request_state_when_submitted(funding_application, payment_request)
    
    payment_request.payload_submitted = { 
      account_name: funding_application.payment_details.account_name, 
      account_number: funding_application.payment_details.account_number,  
      building_society_roll_number: funding_application.payment_details.building_society_roll_number,
      sort_code: funding_application.payment_details.sort_code,
      payment_reference: funding_application.payment_details.payment_reference,
      amount_requested: payment_request.amount_requested
    }

    payment_request.save
    
  end

end