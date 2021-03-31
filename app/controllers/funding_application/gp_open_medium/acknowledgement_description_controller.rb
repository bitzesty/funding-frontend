# Controller for the 'How do you plan to acknowledge your grant?'
# question of the open medium application journey
class FundingApplication::GpOpenMedium::AcknowledgementDescriptionController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the acknowledgement_description attribute of an OpenMedium, redirecting to
  # :funding_application_open_medium_jobs_or_apprenticeships if
  # successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating acknowledgement_description for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_acknowledgement_description = true

    @funding_application.open_medium.update(open_medium_params)

    if @funding_application.open_medium.valid?

      logger.info(
        'Finished updating acknowledgement_description for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_jobs_or_apprenticeships

    else

      logger.info(
        'Validation failed when attempting to update acknowledgement_description ' \
        "for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:acknowledgement_description)

  end

end
