class FundingApplication::ProgressAndSpend::ProgressUpdate::Risk::RiskAddController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  
  def show()

    @risk =
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_risk.build

  end

  def update()

    @risk =
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_risk.build

    assign_is_still_risk_description_param(@risk, params)

    toggle_risk_validation(@risk, params)

    @risk.update(risk_permitted_params(params))

    unless @risk.errors.any?

      redirect_to(
        funding_application_progress_and_spend_progress_update_risk_risk_summary_path(
            progress_update_id:
              @funding_application.arrears_journey_tracker.progress_update.id
        )
      )

    else

      render :show
    
    end

  end

end
  