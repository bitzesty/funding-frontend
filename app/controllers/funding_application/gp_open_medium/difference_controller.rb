# Controller for the 'what difference will your project make'
# question of the open medium application journey
class FundingApplication::GpOpenMedium::DifferenceController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the difference attribute of an OpenMedium, redirecting to
  # :funding_application_open_medium_at_risk if
  # successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating difference for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_difference = true

    @funding_application.open_medium.update(open_medium_params)

    if @funding_application.open_medium.valid?

      logger.info(
        'Finished updating difference for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_at_risk

    else

      logger.info(
        'Validation failed when attempting to update difference ' \
        "for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:difference)

  end

end
