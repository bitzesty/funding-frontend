# Controller for the 'how will you evaluate your project'
# question of the open medium application journey
class FundingApplication::GpOpenMedium::EvaluationDescriptionController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the evaluation_description attribute of an OpenMedium, redirecting to
  # :todo if
  # successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating evaluation_description for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_evaluation_description = true

    @funding_application.open_medium.update(open_medium_params)

    if @funding_application.open_medium.valid?

      logger.info(
        'Finished updating evaluation_description for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      # redirect_to(:todo)
      render :show

    else

      logger.info(
        'Validation failed when attempting to update evaluation_description ' \
        "for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:evaluation_description)

  end

end
