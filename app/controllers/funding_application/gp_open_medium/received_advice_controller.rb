# Controller for a page that asks about what advice an
# applicant has received.
class FundingApplication::GpOpenMedium::ReceivedAdviceController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the received_advice_description attribute of an
  # organisation, redirecting to
  # :funding_application_gp_open_medium_board_members_or_trustees if
  # successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating received_advice_description for ' \
      "gp_open_medium ID: #{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_received_advice_description = true

    @funding_application.open_medium.update(gp_open_medium_params)

    if @funding_application.open_medium.valid?

      logger.info(
        'Finished updating received_advice_description ' \
        "for gp_open_medium ID: #{@funding_application.open_medium.id}"
      )

      # redirect_to :funding_application_gp_open_medium_board_members_or_trustees
      render :show

    else

      logger.info(
        'Validation failed when attempting to update' \
        'received_advice_description for gp_open_medium ' \
        "ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def gp_open_medium_params

    params.fetch(:open_medium, {}).permit(:received_advice_description)

  end

end
