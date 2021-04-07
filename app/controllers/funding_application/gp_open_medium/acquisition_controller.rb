# Controller for a page that asks whether heritage is at risk
class FundingApplication::GpOpenMedium::AcquisitionController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the acquisition attribute of an open medium
  # redirecting to
  # :TODO if
  # successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating acquisition for funding_application ' \
      "ID: #{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_acquisition = true

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating acquisition for funding_application ' \
        "ID: #{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_do_you_need_permission

    else

      logger.info(
        'Validation failed when attempting to update acquisition ' \
        "for funding_application ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:acquisition)

  end

end
