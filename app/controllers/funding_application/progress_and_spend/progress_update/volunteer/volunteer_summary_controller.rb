class FundingApplication::ProgressAndSpend::ProgressUpdate::\
  Volunteer::VolunteerSummaryController < ApplicationController
  include FundingApplicationContext

    def show()
      get_volunteers 
    end

    def update()

      progress_update.validate_add_another_volunteer = true

      progress_update.add_another_volunteer = 
      params[:progress_update].nil? ? nil : 
        params[:progress_update][:add_another_volunteer]
  
      if progress_update.valid?
        if progress_update.add_another_volunteer == "true"
          redirect_to(
            funding_application_progress_and_spend_progress_update_volunteer_volunteer_add_path(
              progress_update_id:  \
                @funding_application.arrears_journey_tracker.progress_update.id
            )
          )
        else
          redirect_to(
            funding_application_progress_and_spend_progress_update_non_cash_contribution_non_cash_contribution_question_path(
              progress_update_id:  \
                @funding_application.arrears_journey_tracker.progress_update.id
            )
          )
        end
      else
        get_volunteers
        render :show
      end
    end

    def delete()

      logger.info(
      'Deleting volunteer with id: ' \
      "#{params[:volunteer_id]} from propress_update ID: " \
      "#{params[:progress_update_id]}"
    )

    ProgressUpdateVolunteer.destroy(params[:volunteer_id])

    redirect_to(
      funding_application_progress_and_spend_progress_update_volunteer_volunteer_summary_path(
          progress_update_id:
            @funding_application.arrears_journey_tracker.progress_update.id
      )
    )

  end

  private

  def get_volunteers
    @volunteers = @funding_application.arrears_journey_tracker
      .progress_update.progress_update_volunteer
  end

  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end

end
