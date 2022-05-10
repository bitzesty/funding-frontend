class FundingApplication::ProgressAndSpend::ProgressUpdate::\
  Volunteer::VolunteerQuestionController < ApplicationController
  include FundingApplicationContext

  def show()
    initialise_form_vars
  end

  def update()

    progress_update.validate_has_volunteer_update = true

    progress_update.update(get_params(params))

    if progress_update.has_volunteer_update == 'false'

      update_json(progress_update.answers_json, false)

      # redirect to non cash contributions

      redirect_to(
        funding_application_progress_and_spend_progress_update_non_cash_contribution_non_cash_contribution_question_path(
          progress_update_id:  \
            @funding_application.arrears_journey_tracker.progress_update.id
        )
      )

    elsif progress_update.has_volunteer_update == 'true'

      update_json(progress_update.answers_json, true)

      # If there are already existing volunteers (this is a return journey)
      # then route to volunteers summary. 
      if  progress_update.progress_update_volunteer.empty? 
        redirect_to(
          funding_application_progress_and_spend_progress_update_volunteer_volunteer_add_path(
              progress_update_id:
                @funding_application.arrears_journey_tracker.progress_update.id
          )
        )
      else
        redirect_to(
          funding_application_progress_and_spend_progress_update_volunteer_volunteer_summary_path(
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
      :has_volunteer_update
    )
  end

  def update_json(answers_json, answer)
    answers_json['volunteer']['has_volunteer_update'] = answer
    progress_update.answers_json = answers_json
    progress_update.save
  end


  def initialise_form_vars
    progress_update.has_volunteer_update = progress_update.answers_json['volunteer']['has_volunteer_update']
  end

end
