class FundingApplication::GpOpenMedium::EvidenceOfSupportController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method is used to set the @has_file_upload instance variable before
  # rendering the :show template. This is used within the
  # _direct_file_upload_hooks partial
  def show

    @has_file_upload = true

     # Empty flash values to ensure that we don't redisplay them unnecessarily
     flash[:description] = ''

  end

  # This method adds evidence of support to a funding_application, redirecting
  # back to :funding_application_gp_project_evidence_of_support if successful
  # and re-rendering :show method if unsuccessful
  def update

    # Empty flash values to ensure that we don't redisplay them unnecessarily
    flash[:description] = ''

    logger.info(
      'Adding evidence of support for funding_application ID: ' \
      "#{@funding_application.id}"
    )

    @funding_application.validate_evidence_of_support = true

    if @funding_application.update(funding_application_params)

      logger.info(
        'Finished adding evidence of support for funding_application ID: ' \
        "#{@funding_application.id}"
      )

      redirect_to :funding_application_gp_open_medium_evidence_of_support

    else

      logger.info(
        'Validation failed when attempting to add evidence of ' \
        "support for funding_application ID: #{@funding_application.id}"
      )

      log_errors(@funding_application)

      # Store flash values to display them again when re-rendering the page
      flash[:description] =
        params['funding_application']['evidence_of_support_attributes']['0']['description']

      render :show

    end

    @has_file_upload = true

  end

  # This method deletes evidence of support, redirecting back to
  # :funding_application_gp_open_medium_evidence_of_support once completed
  def delete

    logger.info(
      'User has selected to delete evidence_of_support ID: ' \
      "#{params[:supporting_evidence_id]} from funding_application ID: " \
      "#{@funding_application.id}"
    )

    evidence_of_support = @funding_application.evidence_of_support
      .find(params[:supporting_evidence_id])

    link_record = FundingApplicationsEvidence.find_by(
      evidence_of_support_id: params[:supporting_evidence_id]
    )

    logger.info("Deleting funding_applications_eos ID: #{ link_record.id }")

    link_record.destroy

    logger.info(
      'Finished deleting funding_applications_eos ID: ' \
      "#{ link_record.id }"
    )

    logger.info "Deleting supporting evidence ID: #{evidence_of_support.id}"

    evidence_of_support.destroy

    logger.info(
      "Finished deleting supporting evidence ID: " \
      "#{evidence_of_support.id}"
    )

    redirect_to :funding_application_gp_open_medium_evidence_of_support

  end

  private

  def funding_application_params

    params.fetch(:funding_application, {}).permit(
      evidence_of_support_attributes: [
        :description,
        :evidence_of_support_files
      ]
    )

  end

end
