# At the time of writing, this is the controller for the page headed:
# "How are you getting a wider range of people involved in the project?"
class FundingApplication::ProgressAndSpend::ProgressUpdate::DemographicController < ApplicationController
  include FundingApplicationContext

  def show()
    @demographic = get_demographic(@funding_application)
  end

  def update()

    @demographic = get_demographic(@funding_application)

    @demographic.update(permitted_params(params))

    unless @demographic.errors.any?

      redirect_to(
        funding_application_progress_and_spend_progress_update_outcome_path(
            progress_update_id:
              @funding_application.arrears_journey_tracker.progress_update.id
        )
      )

    else

      render :show

    end

  end

  private

  # Gets an instance of ProgressUpdateDemographic
  # Checks to see if an instance exists, and returns if so.
  # otherwise builds an in memory instance and returns
  # @param [FundingApplication] funding_application
  # @return [ProgressUpdateDemographic] persisted or in memory instance
  def get_demographic(funding_application)

    progress_update = funding_application.arrears_journey_tracker.progress_update

    progress_update.progress_update_demographic.first.nil? ? \
      progress_update.progress_update_demographic.build : \
        progress_update.progress_update_demographic.first

  end

  # Returns the permitted params
  #
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def permitted_params(params)
    params.require(:progress_update_demographic).permit(:explanation)
  end

end
