class FundingApplication::ProgressAndSpend::SubmitController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  
    def show()
      initialise_view
      retrieve_project_info
    end
  
    def update()
  
    end

    private 

    def initialise_view()

      @submitting_progress_update = false
      @submitting_payment_request = false
      @submitting_bank_details = false

      @submission = 
        @funding_application.completed_arrears_journeys
          .find(params[:completed_arrears_journey_id])
 
        @user_email = current_user.email

        @submitting_progress_update = 
          @submission.progress_update.present?

        if @submission.payment_request.present?
         
          @submitting_bank_details = true if @submission
            .payment_request.answers_json["bank_details_journey"]["has_bank_details_update"] == "true"

          @payment_amount = get_payment_amount(@submission)

          @submitting_payment_request = true if @payment_amount > 0

        end
    end

    def get_payment_amount(completed_arrears_journey)

      details_hash = salesforce_arrears_project_details(@funding_application)
      
      # Account for 40% Payment
      if @funding_application.is_10_to_100k? || 
        @funding_application.dev_to_100k?
        details_hash[:grant_awarded] * 0.4
      else
        get_arrears_payment_amount(
          completed_arrears_journey,
          details_hash[:payment_percentage]
        )
      end

    end

    def retrieve_project_info
  
      details_hash = salesforce_arrears_project_details(@funding_application)
  
      @project_name = details_hash[:project_name]
      @project_reference_num = @funding_application.project_reference_number
      @grant_paid = details_hash[:amount_paid] 
      @remaining_grant = details_hash[:amount_remaining]
      @grant_expiry_date = details_hash[:project_expiry_date]
  
    end

  end
