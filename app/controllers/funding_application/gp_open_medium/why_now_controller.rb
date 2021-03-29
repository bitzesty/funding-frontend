# Controller for a page that asks why a project needs to happen now
class FundingApplication::GpOpenMedium::WhyNowController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the why_now_description attribute of an
  # medium application, redirecting to
  # :funding_application_gp_open_medium_location if
  # successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating why_now_description for ' \
      "gp_open_medium ID: #{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_why_now_description = true

    @funding_application.open_medium.update(gp_open_medium_params)

    if @funding_application.open_medium.valid?

      logger.info(
        'Finished updating why_now_description ' \
        "for gp_open_medium ID: #{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_location

    else

      logger.info(
        'Validation failed when attempting to update' \
        'why_now_description for gp_open_medium ' \
        "ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def gp_open_medium_params

    params.fetch(:open_medium, {}).permit(:why_now_description)

  end

end
