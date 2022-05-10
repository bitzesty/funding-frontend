class FundingApplication::ProgressAndSpend::ProgressUpdate::\
  NonCashContribution::NonCashContributionQuestionController < ApplicationController
  include FundingApplicationContext

  def show()
    initialise_form_vars
  end

  def update()

    progress_update.validate_has_non_cash_contribution = true

    progress_update.update(get_params(params))

    if progress_update.has_non_cash_contribution == 'false'

      update_json(progress_update.answers_json, false)

       # redirect to check answers

      redirect_to(
      funding_application_progress_and_spend_progress_update_check_your_answers_path(
        progress_update_id:  \
          @funding_application.arrears_journey_tracker.progress_update.id
        )
      )

    elsif progress_update.has_non_cash_contribution == 'true'

      update_json(progress_update.answers_json, true)

      # If there are already existing non cc (this is a return journey)
      # then route to non cc summary. 
      if progress_update.progress_update_non_cash_contribution.empty?
        redirect_to(
          funding_application_progress_and_spend_progress_update_non_cash_contribution_non_cash_contribution_add_path(
              progress_update_id:
                @funding_application.arrears_journey_tracker.progress_update.id
          )
        )
      else
        redirect_to(
          funding_application_progress_and_spend_progress_update_non_cash_contribution_non_cash_contribution_summary_path(
              progress_update_id:
                @funding_application.arrears_journey_tracker.progress_update.id
          )
        )
      end

    else
      
      # earlier update will add errors to the object
      render :show

    end

  end

  private

  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end

  def get_params(params)
    params.fetch(:progress_update, {}).permit(
      :has_non_cash_contribution
    )
  end

  def update_json(answers_json, answer)
    answers_json['non_cash_contribution']['has_non_cash_contribution']= answer
    progress_update.answers_json = answers_json
    progress_update.save
  end

  def initialise_form_vars
    progress_update.has_non_cash_contribution = progress_update.answers_json['non_cash_contribution']['has_non_cash_contribution']
  end

end