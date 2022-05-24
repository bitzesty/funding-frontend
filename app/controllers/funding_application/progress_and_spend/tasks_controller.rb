class FundingApplication::ProgressAndSpend::TasksController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  include Enums::ArrearsJourneyStatus
  
    def show()

      if arrears_journey_tracker.nil?
        redirect_to :authenticated_root
      end

      retrieve_project_info

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
      submit_to_salesforce if params.has_key?(:submit_button) 
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

    def retrieve_project_info

      details_hash = salesforce_arrears_project_details(@funding_application)
  
      @project_name = details_hash[:project_name]
      @project_reference_num = @funding_application.project_reference_number
      @grant_paid = details_hash[:amount_paid] 
      @remaining_grant = details_hash[:amount_remaining]
      @grant_expiry_date = details_hash[:project_expiry_date]
  
    end

    def submit_to_salesforce()

      completed_arrears_journey = get_completed_arrears_journey

      upload_arrears_to_salesforce(@funding_application, completed_arrears_journey)

      arrears_journey_tracker.delete

      redirect_to funding_application_progress_and_spend_submit_your_answers_path(
        completed_arrears_journey_id: completed_arrears_journey.id )

    end

    def get_completed_arrears_journey

      completed_arrears_journey = 
        @funding_application.completed_arrears_journeys
          .where(
            progress_update_id: progress_update&.id, 
            payment_request: payment_request&.id 
          )

      if completed_arrears_journey.empty?
        completed_arrears_journey = @funding_application
          .completed_arrears_journeys.create(
            payment_request_id:payment_request&.id,
            progress_update_id: progress_update&.id,
            submitted_on: DateTime.now()
          )
      end

      completed_arrears_journey

    end

    helper_method :get_tag_colour
  end
