# Controller for the 'how is your project managed' question that forms
# part of the open medium grant programme journey
class FundingApplication::GpOpenMedium::ManagedController < ApplicationController
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
      'Updating management_description for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    set_validation(
      @funding_application,
      params
    )

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating management_description for ' \
        "open_medium ID: #{@funding_application.open_medium.id}"
      )

      redirect_based_on_risk_register_param_presence(params)

    else

      logger.info(
        'Validation failed when attempting to update management_description' \
        " for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(
      :management_description,
      :risk_register_file
    )

  end

  # Method used to determine which model object attributes to validate
  #
  # If no parameters are passed, but a risk_register_file has been attached,
  # then no validation should occur. If no parameters are passed and no
  # risk_register_file is present, then the management_description attribute
  # should be validated for presence.
  #
  # If a management_description param is present, then it's length should
  # be validated.
  #
  # @param [FundingApplication] funding_application An instance of FundingApplication
  # @ param [Params] params Incoming form parameters
  def set_validation(funding_application, params)

    if (
      !params[:open_medium][:management_description].present? &&
      !params[:open_medium][:risk_register_file].present? &&
      !funding_application.open_medium.risk_register_file.attached?
    )

      funding_application.open_medium.validate_management_description_presence = true

    end

    funding_application.open_medium.validate_management_description_length = true if
      params[:open_medium][:management_description].present?

  end

  # Method used to determine and enact redirect path
  #
  # If a risk_register_file param is present, then the user should be
  # redirected to the same page, so that their file upload can be confirmed
  # if necessary, otherwise they should be redirected to the next page
  # in the journey
  #
  # @param [Params] params Incoming form parameters
  def redirect_based_on_risk_register_param_presence(params)

    if params[:open_medium][:risk_register_file].present?

      redirect_to :funding_application_gp_open_medium_how_will_your_project_be_managed

    else

      redirect_to :funding_application_gp_open_medium_how_will_you_evaluate_your_project

    end

  end

end
