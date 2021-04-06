# Controller for a page that asks for project image file uploads
class FundingApplication::GpOpenMedium::ProjectImagesController < ApplicationController
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
      'Updating project_image_files for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_project_image_files = true

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating project_image_files for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_project_images

    else

      logger.info(
        "Validation failed when attempting to update project_image_files" \
        " for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:project_image_files => [])

  end

end
