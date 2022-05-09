class FundingApplication::ProgressAndSpend::TasksController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  include Enums::ArrearsJourneyStatus
  
    def show()

      retrieve_project_info

      @submit_status = :cannot_start

      @complete_progress_tasks =  \
        @funding_application.arrears_journey_tracker.\
          progress_update_id.present?
      
      @complete_payment_tasks = \
        @funding_application.arrears_journey_tracker.\
          payment_request_id.present?

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
        @can_submit = submitted_progress_update && submitted_payment_tasks#
      elsif @complete_payment_tasks
        @can_submit = submitted_payment_tasks
      elsif  @complete_progress_tasks
        @can_submit = submitted_progress_update
      end

      @submit_status = :not_started if @can_submit

    end
  
    def update()
  
    end

    private

    def progress_update
      @funding_application.arrears_journey_tracker.progress_update
    end

    def payment_request
      @funding_application.arrears_journey_tracker.payment_request
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

    helper_method :get_tag_colour
  end
