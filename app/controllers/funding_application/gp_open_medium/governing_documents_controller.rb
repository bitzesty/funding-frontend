# Controller for the governing documents question within the open
# medium grant programme journey
class FundingApplication::GpOpenMedium::GoverningDocumentsController < ApplicationController
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
      'Updating governing_document_file for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.update(open_medium_params)

    @funding_application.open_medium.validate_governing_document_file = true

    if @funding_application.open_medium.valid?

      logger.info(
        'Finished updating governing_document_file for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_governing_documents

    else

      logger.info(
        'Validation failed when attempting to update governing_document_file' \
        " for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(:governing_document_file)

  end

end
