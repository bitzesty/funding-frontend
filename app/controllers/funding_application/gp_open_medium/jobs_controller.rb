class FundingApplication::GpOpenMedium::JobsController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method is used to set the @has_file_upload instance variable before
  # rendering the :show template. This is used within the
  # _direct_file_upload_hooks partial
  def show
    @has_file_upload = true
  end

  def update

    logger.info(
      'Updating job_description_files for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_job_description_files = true

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating job_description_files for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_jobs_or_apprenticeships

    else

      logger.info(
        "Validation failed when attempting to update job_description_files" \
        " for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:job_description_files => [])

  end

end
