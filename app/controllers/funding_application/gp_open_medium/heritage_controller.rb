class FundingApplication::GpOpenMedium::HeritageController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the heritage_description attribute of an 
  # open_medium redirecting to
  # :funding_application_gp_open_medium_why_is_your_organisation_best_placed
  # if successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating heritage_description for open medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_heritage_description = true

    if @funding_application.open_medium.update(open_medium_params)

      logger.debug(
        'Finished updating heritage_description for open_medium ' \
        "ID: #{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_why_is_your_organisation_best_placed

    else

      logger.info(
        'Validation failed when attempting to update heritage_description ' \
        "for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:heritage_description)

  end

end
