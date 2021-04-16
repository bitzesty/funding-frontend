# Controller related to a view which asks for a narrative description of
# jobs and apprenticeships being created as part of a project, as well as
# for related file uploads
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
      'Updating jobs_or_apprenticeships_description and ' \
      'job_description_files for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium
      .validate_jobs_or_apprenticeships_description = true

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating jobs_or_apprenticeships_description and ' \
        'job_description_files for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      redirect_based_on_job_description_files_param_presence(params)

    else

      logger.info(
        'Validation failed when attempting to update job_description_files' \
        'and jobs_or_apprenticeships_description for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(
      :jobs_or_apprenticeships_description,
      :job_description_files => []
    )

  end

  # Method used to determine and enact redirect path
  #
  # If a job_description_files param is present, then the user should be
  # redirected to the same page, so that their file upload can be confirmed
  # if necessary, otherwise they should be redirected to the next page
  # in the journey
  #
  # @param [Params] params Incoming form parameters
  def redirect_based_on_job_description_files_param_presence(params)

    if params[:open_medium][:job_description_files].present?

      redirect_to :funding_application_gp_open_medium_jobs_or_apprenticeships

    else

      redirect_to :funding_application_gp_open_medium_costs

    end

  end

end
