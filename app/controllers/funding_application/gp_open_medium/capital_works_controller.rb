# Controller for 'Will capital work be part of your project' page
class FundingApplication::GpOpenMedium::CapitalWorksController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method is used to set the @has_file_upload instance variable before
  # rendering the :show template. This is used within the
  # _direct_file_upload_hooks partial
  def show
    @has_file_upload = true
  end

  # This method updates the capital_work and capital_work_file attributes of an
  # OpenMedium, redirecting to
  # :funding_application_gp_open_medium_acquisition if
  # successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating capital_work for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_capital_work = true

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating capital_work for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      # Redirect the user back to the same page if they were uploading a
      # capital work file - this is so that we can display the file back to
      # the user so they can check that they have uploaded the correct file

      if params[:open_medium][:capital_work_file].present?
        redirect_to :funding_application_gp_open_medium_capital_works
      else
        redirect_to :funding_application_gp_open_medium_acquisition
      end

    else

      logger.info(
        'Validation failed when attempting to update capital_work ' \
        "for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:capital_work, :capital_work_file)

  end

end
