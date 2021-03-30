class FundingApplication::GpOpenMedium::InvolvementController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the involvement_description attribute of an
  # open_medium, redirecting to
  # :funding_application_gp_open_medium_our_other_outcomes if
  # successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating involvement_description for open_medium ' \
      "ID: #{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_involvement_description = true

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating project involvement_description for ' \
        "open_medium ID: #{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_our_other_outcomes

    else

      logger.info(
        'Validation failed when attempting to update involvement_description ' \
        "for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:involvement_description)

  end

end
