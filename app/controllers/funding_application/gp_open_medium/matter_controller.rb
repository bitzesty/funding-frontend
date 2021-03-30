class FundingApplication::GpOpenMedium::MatterController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def update

    logger.info(
      'Updating matter for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_matter = true

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating matter for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_environmental_impacts

    else

      logger.info(
        'Validation failed when attempting to update matter for ' \
        "open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:matter)

  end

end
