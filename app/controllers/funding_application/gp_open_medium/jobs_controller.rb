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

  # Rails 7 always populates the first item in the files array with a
  # blank string. This blank string will erase any files already attached.
  # So to prevent form re-renders from wiping files, only update
  # :job_description_files when actual files are provided in params.
  def update

    logger.info(
      'Updating jobs_or_apprenticeships_description and ' \
      'job_description_files for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium
      .validate_jobs_or_apprenticeships_description = true

    @funding_application.open_medium.jobs_or_apprenticeships_description =
      open_medium_params[:jobs_or_apprenticeships_description]

    @funding_application.open_medium.job_description_files =
      open_medium_params[:job_description_files] unless
        file_array_empty?(open_medium_params)

    if @funding_application.open_medium.valid?

      @funding_application.open_medium.save

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
  # If job_description_files DON'T exist, then the user should be
  # redirected to the next page.
  # If job_description_files DO exist, reload the page so that their
  # file upload can be confirmed
  #
  # @param [Params] params Incoming form parameters
  def redirect_based_on_job_description_files_param_presence(params)

    if file_array_empty?(open_medium_params)

      redirect_to :funding_application_gp_open_medium_costs

    else

      redirect_to :funding_application_gp_open_medium_jobs_or_apprenticeships

    end

  end

  # Returns true if :job_description_files
  # @params [Hash] permitted_params
  # @return [Boolean]
  def file_array_empty?(permitted_params)
    permitted_params[:job_description_files].first.blank? &&
      permitted_params[:job_description_files].count == 1
  end

end
