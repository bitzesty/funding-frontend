class FundingApplication::ProgressAndSpend::TasksController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  include Enums::ArrearsJourneyStatus
  include Mailers::ProgressAndSpendMailerHelper
  include PaymentDetailsAndRequestHelper
  
    def show()

      if arrears_journey_tracker.nil?
        redirect_to :authenticated_root
      end

      retrieve_project_info

    # Show if agreements.terms_agreed_at is not null
    # AND the actual agreements table needs to have copies stored.
    # Which isn't the case for older applications.
    @view_signed_agreement =
      @funding_application&.agreement&.terms_agreed_at.present? &&
        @funding_application&.agreement&.project_details_html.present? &&
          @funding_application&.agreement&.terms_html.present?

      @complete_progress_tasks =  \
        @funding_application.arrears_journey_tracker&.\
          progress_update_id.present? ? true : false
      
      @complete_payment_tasks = \
        @funding_application.arrears_journey_tracker&.\
          payment_request_id.present? ? true : false

      if @complete_progress_tasks
        @how_project_going_status = journey_status_string(progress_update
          .answers_json['journey_status']['how_project_going'])
        @approved_purposes_status = journey_status_string(progress_update
          .answers_json['journey_status']['approved_purposes'])

        submitted_progress_update = 
          (@how_project_going_status == :completed && 
            @approved_purposes_status == :completed) ? true : false
      end

      if @complete_payment_tasks
        @payment_request_status = journey_status_string(payment_request
          .answers_json['arrears_journey']['status'])

        @bank_details_status = journey_status_string(payment_request
          .answers_json['bank_details_journey']['status'])

        submitted_payment_tasks = 
          (@payment_request_status == :completed && 
            @bank_details_status == :completed) ? true : false
      end

      if @complete_progress_tasks && @complete_payment_tasks
        @can_submit = submitted_progress_update && submitted_payment_tasks
      elsif @complete_payment_tasks
        @can_submit = submitted_payment_tasks
      elsif  @complete_progress_tasks
        @can_submit = submitted_progress_update
      end

    end
  
    def update()
      # submit button only enabled when tasks complete
      if params.has_key?(:submit_button)

        @completed_arrears_journey = get_completed_arrears_journey

        # Gather info for email and calculating payment_request_amount.
        retrieve_project_info(@completed_arrears_journey)

        submit_to_salesforce(
          @arrears_payment_amount,
          @funding_application,
          @completed_arrears_journey
        )

        payment_amount_as_currency_string =
          view_context.number_to_currency(
            @arrears_payment_amount,
            precision: 2
          )

        send_confirmation_email(
          @completed_arrears_journey,
          @project_name,
          @project_reference_num,
          payment_amount_as_currency_string
        )

      end

    end

    private

    def progress_update
      @funding_application.arrears_journey_tracker&.progress_update
    end

    def payment_request
      @funding_application.arrears_journey_tracker&.payment_request
    end

    def arrears_journey_tracker
      @funding_application.arrears_journey_tracker
    end

    def get_tag_colour(status) 
      case status
      when :in_progress
        colour = 'blue'
      when :completed
        colour = 'grey'
      when :cannot_start
        colour = 'grey'
      else
        colour = ''
      end

      colour
    end

    def retrieve_project_info(completed_arrears_journey = nil)

      details_hash = salesforce_arrears_project_details(@funding_application)
  
      @project_name = details_hash[:project_name]
      @project_reference_num = @funding_application.project_reference_number
      @grant_paid = details_hash[:amount_paid] 
      @remaining_grant = details_hash[:amount_remaining]
      @grant_expiry_date = details_hash[:project_expiry_date]
      payment_percentage = details_hash[:payment_percentage]
      grant_awarded = details_hash[:grant_awarded]

      if completed_arrears_journey.present?
        # Account for 40% M1 Payment
        if @funding_application.is_10_to_100k? || 
            @funding_application.dev_to_100k? 
          @arrears_payment_amount = grant_awarded * 0.4
        else
          @arrears_payment_amount = get_arrears_payment_amount(
            completed_arrears_journey,
            payment_percentage
          )  
        end

      end

    end

    # Calls orchestration method to upload arrears data to Salesforce
    #
    # Upon successful execution, deletes the arrears_journey_tracker
    # to allow new progress/payment requests to begin.
    #
    # Also deletes any stored payment details (which includes bank accounts).
    # These should only remain in Salesforce.
    #
    # @param [FundingApplication] funding_application An instance of
    #                                                 FundingApplication
    # @param [CompletedArrearsJourney] completed_arrears_journey
    #                                                 An instance of
    #                                                 CompletedArrearsJourney
    # @param [Float] payment_amount Value of the payment request
    def submit_to_salesforce(
      payment_amount,
      funding_application,
      completed_arrears_journey
    )

      if completed_arrears_journey.payment_request.present?
        store_payment_request_state_when_submitted(
          funding_application,
          payment_request
        ) # store for support should request fail.
        update_payment_request_amount(payment_request, payment_amount)
      end

      upload_arrears_to_salesforce(
        @funding_application,
        @completed_arrears_journey,
        payment_amount
      )

      # payment request in salesforce, so clear support data
      payment_request.update(payload_submitted: nil) if
        completed_arrears_journey.payment_request.present?

      arrears_journey_tracker&.delete
      funding_application.payment_details&.delete

      funding_application.update(status: :m1_40_payment_complete) if \
        funding_application.m1_40_payment_can_start?

      funding_application.update(status: :dev_40_payment_complete) if \
        funding_application.dev_40_payment_can_start?

      redirect_to funding_application_progress_and_spend_submit_your_answers_path(
        completed_arrears_journey_id: @completed_arrears_journey.id )

    end

    # Finds matching completed_arrears_journey rows with a matching
    # payment_request.id and progress_update.id combination.
    # There should only be one - so only return first if anything found.
    #
    # If no matches found, creates a new completed_arrears_journey instance.
    #
    # @return [CompletedArrearsJourney] 
    #                  @funding_application.completed_arrears_journeys.first
    def get_completed_arrears_journey

      matching_completed_arrears_journeys = 
        @funding_application.completed_arrears_journeys
          .where(
            progress_update_id: progress_update&.id, 
            payment_request: payment_request&.id 
          )

      if matching_completed_arrears_journeys.empty?
        completed_arrears_journey = 
          @funding_application.completed_arrears_journeys.create(
            payment_request_id:payment_request&.id,
            progress_update_id: progress_update&.id,
            submitted_on: DateTime.now()
          )
      else
        completed_arrears_journey = 
          matching_completed_arrears_journeys.first
      end

      completed_arrears_journey

    end

    helper_method :get_tag_colour
  end
