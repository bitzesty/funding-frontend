# Controller for a page that asks for a 'project plan' file upload
class FundingApplication::GpOpenMedium::ProjectPlanController < ApplicationController
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
      'Updating project_plan_file for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_project_plan_file = true

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating project_plan_file for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_project_plan

    else

      logger.info(
        "Validation failed when attempting to update project_plan_file" \
        " for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:project_plan_file)

  end

end
