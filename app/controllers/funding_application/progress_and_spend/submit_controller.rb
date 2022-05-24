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

      @submission = 
        @funding_application.completed_arrears_journeys
          .find(params[:completed_arrears_journey_id])
 
        @user_email = current_user.email

        @submitting_progress_update = 
          @submission.progress_update.present?

        if @submission.payment_request.present?
          @submitting_payment_request = true
          @submitting_bank_details = true if @submission
            .payment_request.answers_json["bank_details_journey"]["has_bank_details_update"] == "true"
        end

        # TODO: Pull down payment amount
        @payment_amount = 1000

        # TODO: Pull down payment percentage
        @payment_percentage = 85

    end

  end
