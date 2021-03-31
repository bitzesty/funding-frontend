class FundingApplication::GpOpenMedium::PermissionController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def update

    logger.info(
      'Updating permission attributes for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_permission_type = true

    if params[:open_medium].present?

      if params[:open_medium][:permission_type].present?

        # Ensure that we remove any previous descriptions if a user
        # selects the 'no' radio button
        if params[:open_medium][:permission_type] == 'no'
          @funding_application.open_medium.permission_description = nil
        end

        if params[:open_medium][:permission_type] == "yes"

          @funding_application.open_medium.permission_description =
              params[:open_medium][:permission_description_yes].present? ?
                  params[:open_medium][:permission_description_yes] : nil

          @funding_application.open_medium.validate_permission_description_yes = true

        end

        if params[:open_medium][:permission_type] == "x_not_sure"

          @funding_application.open_medium.permission_description =
              params[:open_medium][:permission_description_x_not_sure].present? ?
                  params[:open_medium][:permission_description_x_not_sure] : nil

          @funding_application.open_medium.validate_permission_description_x_not_sure = true

        end

      end

    end

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating permission attributes for ' \
        "open_medium ID: #{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_project_difference

    else

      logger.info(
        'Validation failed when attempting to update permission ' \
        "attributes for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.require(:open_medium).permit(
      :permission_type,
      :permission_description_yes,
      :permission_description_x_not_sure
    )

  end

end
