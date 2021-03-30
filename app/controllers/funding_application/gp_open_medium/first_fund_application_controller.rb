# Controller for a page that asks whether this is the
# first funding application by the applicant
class FundingApplication::GpOpenMedium::FirstFundApplicationController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the first_fund_application, recent_project_title
  # and recent_project_reference attributes of an GpOpenMedium application,
  # redirecting to :funding_application_gp_open_medium_title if successful
  # and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating first_fund_application attrubute for ' \
      "gp_open_medium ID: #{@funding_application.open_medium.id}"
    )
    
    @funding_application.open_medium.validate_first_fund_application = true

    clear_or_validate_previous_details(
      @funding_application.open_medium,
      params
    )

    @funding_application.open_medium.update(open_medium_params)

    if @funding_application.open_medium.valid?

      logger.info(
        'Finished updating first_fund_application ' \
        "for gp_open_medium ID: #{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_title

    else

      logger.info(
        'Validation failed when attempting to update ' \
        'first_fund_application for gp_open_medium ' \
        "ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(
      :first_fund_application,
      :recent_project_reference,
      :recent_project_title
    )

  end

  # If this is the organisation's first application, then we
  # should clear any existing recent project titles or
  # reference numbers, otherwise we should validate these
  # incoming params
  #
  # @param [OpenMedium] open_medium An instance of an OpenMedium
  # @param [Params] params The incoming form parameters
  def clear_or_validate_previous_details(open_medium, params)

    if params[:open_medium][:first_fund_application] == 'true'
      params[:open_medium][:recent_project_reference] = nil
      params[:open_medium][:recent_project_title] = nil
    end

    if params[:open_medium][:first_fund_application] == 'false'
      open_medium.validate_recent_project_reference = true
      open_medium.validate_recent_project_title = true
    end

  end

end
