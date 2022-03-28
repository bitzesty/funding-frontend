class FundingApplication::ProgressAndSpend::ProgressUpdate::Risk::RiskSummaryController < ApplicationController
  include FundingApplicationContext

  def show() 
    get_risks
  end

  def update()

    progress_update.validate_add_another_risk = true

    progress_update.add_another_risk = 
    params[:progress_update].nil? ? nil : 
      params[:progress_update][:add_another_risk]

    if progress_update.valid?
      if progress_update.add_another_risk == "true"
        redirect_to(
          funding_application_progress_and_spend_progress_update_risk_risk_add_path(
            progress_update_id:  \
              @funding_application.arrears_journey_tracker.progress_update.id
          )
        )
      else
        redirect_to(
          funding_application_progress_and_spend_progress_update_cash_contribution_cash_contribution_question_path(
            progress_update_id:  \
              @funding_application.arrears_journey_tracker.progress_update.id
          )
        )
      end
    else
      get_risks
      render :show
    end

  end

  def delete()

     logger.info(
      'Deleting procurement with id: ' \
      "#{params[:risk_id]} from propress_update ID: " \
      "#{params[:progress_update_id]}"
    )

    ProgressUpdateRisk.destroy(params[:risk_id])

    redirect_to(
      funding_application_progress_and_spend_progress_update_risk_risk_summary_path(
          progress_update_id:
            @funding_application.arrears_journey_tracker.progress_update.id
      )
    )

  end

  private 

  def get_risks
    @risks = @funding_application.arrears_journey_tracker
      .progress_update.progress_update_risk
  end

  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end

end
