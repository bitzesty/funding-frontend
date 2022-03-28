class FundingApplication::ProgressAndSpend::ProgressUpdate::Risk::RiskEditController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  
  def show()

    @risk = 
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_risk.find(params[:risk_id])

    populate_is_still_risk_description(@risk)

  end

  def update()

    @risk = 
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_risk.find(params[:risk_id])

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

  private

  # Populates applicant's follow up answer to "is this still a risk".
  # Evaluates whether the applicant has indicated a
  # resolved or ongoing risk.
  # Populates appropriate attr_accessor depending on the radop selected.
  #
  # @params [ProgressUpdateRisk] risk 
  def populate_is_still_risk_description(risk)
    risk.is_still_risk? ? \
      risk.yes_still_a_risk_description = risk.is_still_risk_description : \
        risk.no_still_a_risk_description = risk.is_still_risk_description
  end

end
  