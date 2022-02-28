class FundingApplication::ProgressAndSpend::TasksController < ApplicationController
  include FundingApplicationContext
  
    def show()

      @complete_progress_tasks =  \
        @funding_application.arrears_journey_tracker.\
          progress_update_id.present?
      
      @complete_payment_tasks = \
        @funding_application.arrears_journey_tracker.\
          progress_update_id.present?

  
    end
  
    def update()
  
    end
  
  end
