class FundingApplication::ProgressAndSpend::ProgressUpdate::DigitalOutputsQuestionController < ApplicationController
  include FundingApplicationContext

    def show()

      progress_update = 
        @funding_application.arrears_journey_tracker.progress_update
      
      progress_update.has_digital_outputs = \
        progress_update.answers_json['digital_outputs']\
          ['has_digital_outputs'] if \
            progress_update.answers_json.has_key?('digital_outputs')

    end

    def update()

      progress_update = 
        @funding_application.arrears_journey_tracker.progress_update

      progress_update.validate_has_digital_outputs = true

      progress_update.update(required_params(params))

      unless progress_update.errors.any?

        update_json(progress_update)

        redirect_to(
          funding_application_progress_and_spend_progress_update_digital_outputs_description_path(
            progress_update_id:  \
              @funding_application.arrears_journey_tracker.progress_update.id
          )
        ) if progress_update.has_digital_outputs == "true"

        redirect_to(
          funding_application_progress_and_spend_progress_update_funding_acknowledgement_path(
            progress_update_id:  \
              @funding_application.arrears_journey_tracker.progress_update.id
          )
        ) if progress_update.has_digital_outputs == "false"

      else

        render :show

      end

    end

    private

    # Returns the required params.
    # @params [ActionController::Parameters] params A hash of params
    # @return [ActionController::Parameters] params A hash of filtered params
    def required_params(params)
      params.fetch(:progress_update, {}).permit(
        :has_digital_outputs
      )
    end

    # Updates progress update with has_digital_outputs answer
    # Will be "true" or "false" as a string.
    # @params [ProgressUpdate] progress_update instance with answers_json
    def update_json(progress_update)

      progress_update.answers_json['digital_outputs'] = \
        {has_digital_outputs: progress_update.has_digital_outputs}

      progress_update.save

    end

end
