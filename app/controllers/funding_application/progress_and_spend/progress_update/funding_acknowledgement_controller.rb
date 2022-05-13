class FundingApplication::ProgressAndSpend::ProgressUpdate::FundingAcknowledgementController < ApplicationController
  include FundingApplicationContext

    def show()

    end
  
    def update()

      redirect_to(
        funding_application_progress_and_spend_progress_update_check_outcome_answers_path(
          progress_update_id:  \
            @funding_application.arrears_journey_tracker.progress_update.id
        )
      )
  
    end
  
  end
