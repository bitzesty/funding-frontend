class FundingApplication::ProgressAndSpend::ProgressUpdate::CompletionDateController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()
    initialise_form_vars
  end

  def update()

    progress_update.validate_date_correct = true

    progress_update.update(get_params(params))

    if progress_update.date_correct == 'false'

      update_json(progress_update.answers_json, false)

      redirect_to(
        funding_application_progress_and_spend_progress_update_change_completion_date_path(
            progress_update_id:
              @funding_application.arrears_journey_tracker.progress_update.id
        )
      )
    
    elsif progress_update.date_correct == 'true'

      update_json(progress_update.answers_json, true)

      redirect_to(
        funding_application_progress_and_spend_progress_update_permissions_or_licences_path(
            progress_update_id:
              @funding_application.arrears_journey_tracker.progress_update.id
        )
      )

    else

      initialise_form_vars
      # earlier update will add errors to the object
      render :show

    end

  end

  private

  # Returns the permitted params
  # params.fetch(:foo, {}).permit(:bar, :baz) allows :foo to be optional
  #
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def get_params(params)
    params.fetch(:progress_update, {}).permit(
      :date_correct
    )
  end

  # updates json with a new key value pair
  # In this case, whether the grant expiry date is correct.
  # @params [jsonb] answers_json Json containing journey answers
  # @params [Boolean] answer Either true or false
  def update_json(answers_json, answer)
    answers_json['new_expiry_date']['date_correct'] = answer
    progress_update.answers_json = answers_json
    progress_update.save
  end

  # Returns an instance of ProgressUpdate for current context
  # @return [ProgressUpdate]
  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end

  # populate instance variables for use by the form
  def initialise_form_vars
    @completion_date = salesforce_project_expiry_date(@funding_application)
    progress_update.date_correct = progress_update.answers_json['new_expiry_date']['date_correct']
  end

end
