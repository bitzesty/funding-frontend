# Controller for the project title page of the funding application journey
class FundingApplication::GpOpenMedium::TitleController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the project_title attribute of an OpenMedium,
  # redirecting to :three_to_ten_k_project_key_dates if successful and
  # re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating project_title for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_title = true

    @funding_application.open_medium.update(open_medium_params)

    if @funding_application.open_medium.valid?

      logger.info(
        'Finished updating project_title for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      # redirect_to :funding_application_gp_open_medium_key_dates
      render :show

    else

      logger.info(
        'Validation failed when attempting to update project_title ' \
        "for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params
    params.require(:open_medium).permit(:project_title)
  end

end
