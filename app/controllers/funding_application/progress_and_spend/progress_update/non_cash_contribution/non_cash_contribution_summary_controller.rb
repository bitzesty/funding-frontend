class FundingApplication::ProgressAndSpend::ProgressUpdate::\
  NonCashContribution::NonCashContributionSummaryController < ApplicationController
  include FundingApplicationContext

  def show()
    get_non_cash_contributions
  end

  def update()

    progress_update.validate_add_another_non_cash_contribution = true

    progress_update.add_another_non_cash_contribution = 
    params[:progress_update].nil? ? nil : 
      params[:progress_update][:add_another_non_cash_contribution]

    if progress_update.valid?
      if progress_update.add_another_non_cash_contribution == "true"
        redirect_to(
          funding_application_progress_and_spend_progress_update_non_cash_contribution_non_cash_contribution_add_path(
            progress_update_id:  \
              @funding_application.arrears_journey_tracker.progress_update.id
          )
        )
      else
        # redirect to check your answers

        redirect_to(
          funding_application_progress_and_spend_progress_update_check_your_answers_path(
            progress_update_id:  \
              @funding_application.arrears_journey_tracker.progress_update.id
          )
        )
      end
    else
      get_non_cash_contributions
      render :show
    end
  end

  def delete()

    logger.info(
    'Deleting non_cash_contribution with id: ' \
    "#{params[:non_cash_contribution_id]} from propress_update ID: " \
    "#{params[:progress_update_id]}"
  )

  ProgressUpdateNonCashContribution.destroy(params[:non_cash_contribution_id])

  redirect_to(
    funding_application_progress_and_spend_progress_update_non_cash_contribution_non_cash_contribution_summary_path(
        progress_update_id:
          @funding_application.arrears_journey_tracker.progress_update.id
    )
  )

end

private

def get_non_cash_contributions
  @non_cash_contributions = @funding_application.arrears_journey_tracker
    .progress_update.progress_update_non_cash_contribution
end

def progress_update
  @funding_application.arrears_journey_tracker.progress_update
end

end