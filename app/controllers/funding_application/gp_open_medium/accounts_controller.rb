# Controller for the accounts question within the open medium grant programme
# journey
class FundingApplication::GpOpenMedium::AccountsController < ApplicationController
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
      'Updating accounts_files for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_accounts_files = true

    @funding_application.open_medium.update(open_medium_params)

    if @funding_application.open_medium.valid?

      logger.info(
        'Finished updating accounts_files for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_accounts

    else

      logger.info(
        'Validation failed when attempting to update accounts_files ' \
        "for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:accounts_files => [])

  end

end
