class FundingApplication::LegalAgreements::AdditionalDocsController < ApplicationController
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
      'Updating additional_evidence_files for funding_application ID:' \
      "#{@funding_application.id}"
    )

    @funding_application.validate_new_evidence = true

    @funding_application.validate_additional_evidence_files = true if
      params.fetch(:funding_application, {}).fetch(:new_evidence, false) == "true"

    if @funding_application.update(funding_application_params)

      logger.info(
        'Finished updating additional_evidence_files for ' \
        "funding_application ID: #{@funding_application.id}"
      )

      if params.fetch(:funding_application, {})
        .fetch(:additional_evidence_files, false) == "true"
        redirect_to :funding_application_additional_documents
      else
        redirect_to :funding_application_confirm
      end

    else

      logger.info(
        'Validation failed when attempting to update ' \
        'additional_evidence_files for funding_application ID: ' \
        "#{@funding_application.id}"
      )

      log_errors(@funding_application)

      render :show

    end

  end

  private

  def funding_application_params

    params.fetch(:funding_application, {})
      .permit(
        :new_evidence,
        :additional_evidence_files => []
      )

  end

end
