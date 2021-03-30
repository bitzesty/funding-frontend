class FundingApplication::GpOpenMedium::DescriptionController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the description attribute of an OpenMedium,
  # redirecting to :funding_application_gp_open_medium_capital_works
  # if successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating description for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_description = true

    @funding_application.open_medium.update(open_medium_params)

    if @funding_application.open_medium.valid?

      logger.info(
        'Finished updating description for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_capital_works

    else
      logger.info(
        'Validation failed when attempting to update description ' \
        "for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params
    params.require(:open_medium).permit(:description)
  end

end
