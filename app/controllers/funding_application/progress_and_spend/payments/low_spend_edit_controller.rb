class FundingApplication::ProgressAndSpend::Payments::LowSpendEditController \
     < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  
    def show()

      @low_spend = 
        @funding_application.arrears_journey_tracker.payment_request.\
          low_spend.find(params[:low_spend_id])

      @heading = @low_spend.cost_heading
      @spend_threshold = @low_spend.spend_threshold

    end
  
    def update()

      @low_spend = 
        @funding_application.arrears_journey_tracker.payment_request.\
          low_spend.find(params[:low_spend_id])

      @low_spend.validate_vat_amount = true
      @low_spend.validate_total_amount = true

      @low_spend.update(required_params(params))

      unless @low_spend.errors.any?
        
        redirect_to(
          funding_application_progress_and_spend_payments_low_spend_summary_path)
  
      else

        @heading = @low_spend.cost_heading
        @spend_threshold = @low_spend.spend_threshold
  
        render :show
  
      end

    end

    private

    # Returns the required params.
    # @params [ActionController::Parameters] params A hash of params
    # @return [ActionController::Parameters] params A hash of filtered params
    def required_params(params)
      params.require(:low_spend).permit(
        :total_amount,
        :vat_amount
      )
    end
  

  end
