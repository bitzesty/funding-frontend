class FundingApplication::GpOpenMedium::BestPlacedController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the best_placed_description attribute of an open_medium,
  # redirecting to
  # :funding_application_gp_open_medium_partnership
  # if successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating best_placed_description for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_best_placed_description = true

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating best_placed_description for open_medium ' \
        "ID: #{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_delivered_by_a_partnership

    else

      logger.info(
        'Validation failed when attempting to update best_placed_description' \
        "for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:best_placed_description)

  end
  
end
