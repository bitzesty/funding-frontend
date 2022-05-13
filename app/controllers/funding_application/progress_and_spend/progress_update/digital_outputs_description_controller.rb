class FundingApplication::ProgressAndSpend::ProgressUpdate::DigitalOutputsDescriptionController < ApplicationController
  include FundingApplicationContext
  
  def show()

    @digital_output = get_digital_output

  end

  def update()

    @digital_output = get_digital_output

    @digital_output.update(required_params(params))

    unless @digital_output.errors.any?

      redirect_to(
        funding_application_progress_and_spend_progress_update_funding_acknowledgement_path(
          progress_update_id:  \
            @funding_application.arrears_journey_tracker.progress_update.id
        )
      )

    else

      render :show

    end

  end

  private

  # Gets an instance of digital_output
  # Checks to see if an instance exists, and returns if so.
  # otherwise builds an in memory instance and returns
  # @return [ProgressUpdateDigitalOutput]
  def get_digital_output

    progress_update =  @funding_application.arrears_journey_tracker.progress_update

    progress_update.progress_update_digital_output.first.nil? ? \
      progress_update.progress_update_digital_output.build : \
        progress_update.progress_update_digital_output.first

  end

  private

  # Returns the required params.
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def required_params(params)
    params.require(:progress_update_digital_output).permit(
      :description
    )
  end

end
