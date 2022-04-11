class FundingApplication::ProgressAndSpend::SubmitController < ApplicationController
  include FundingApplicationContext
  before_action :authenticate_user!
  
    def show()
      initialise_view
    end
  
    def update()
  
    end

    private 

    def initialise_view()
      @user_email = current_user.email

      @submitting_progress_update = @funding_application
        .arrears_journey_tracker.progress_update.present?

      # TODO: Pulll from JSON
      @submitted_bank_details = false

      # TODO: Pulll from JSON
      @submitted_payment_request = false

      # TODO: Pull down payment amount
      @payment_amount = 1000

      # TODO: Pull down payment percentage
      @payment_percentage = 85

    end
  
  end
