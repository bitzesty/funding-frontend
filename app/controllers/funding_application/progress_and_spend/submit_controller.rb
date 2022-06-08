class FundingApplication::ProgressAndSpend::SubmitController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  before_action :authenticate_user!
  
    def show()
      initialise_view
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

      get_arrears_payment_amount(
        completed_arrears_journey,
        details_hash[:payment_percentage]
      )

    end

  end
