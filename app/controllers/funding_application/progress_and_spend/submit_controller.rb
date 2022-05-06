class FundingApplication::ProgressAndSpend::SubmitController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  before_action :authenticate_user!
  
    def show()
      initialise_view
      submit_to_salesforce
    end
  
    def update()
  
    end

    private 

    def initialise_view()
      @user_email = current_user.email

      @submitting_progress_update = 
        arrears_journey_tracker.progress_update.present?

      if arrears_journey_tracker.payment_request.present?
        @submitting_payment_request = true
        @submitting_bank_details = true if arrears_journey_tracker
          .payment_request.answers_json["bank_details_journey"]["has_bank_details_update"] == "true"
      end

      # TODO: Pull down payment amount
      @payment_amount = 1000

      # TODO: Pull down payment percentage
      @payment_percentage = 85

    end

    def submit_to_salesforce()

      # TODO: When submitting to SF:
      #  - IF only submitting progress update then create progress update form
      #  - IF only payment then create a payments form
      #  - IF BOTH need to create the progress_updates_payments form. 
      if @submitting_progress_update 
        upload_progress_update(
          @funding_application
        )
      end

      completed_arrears_journey =  CompletedArrearsJourney.create(
        funding_application_id: @funding_application.id, 
        payment_request_id: arrears_journey_tracker.payment_request.present? ? 
          arrears_journey_tracker.payment_request.id : nil, 
        progress_update_id: arrears_journey_tracker.progress_update.present? ? 
          arrears_journey_tracker.progress_update.id : nil,
        submitted_on: DateTime.now()
      )

      @funding_application.completed_arrears_journeys << 
        completed_arrears_journey

      @funding_application.save

    end

    def arrears_journey_tracker
      @funding_application.arrears_journey_tracker
    end
  
  end
