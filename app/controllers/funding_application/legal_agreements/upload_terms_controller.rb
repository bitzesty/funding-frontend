class FundingApplication::LegalAgreements::UploadTermsController < ApplicationController
  include FundingApplicationContext
  include FundingApplicationHelper
  include ObjectErrorsLogger
  include LegalAgreementsHelper

  # This method is used to set the @has_file_upload instance variable before
  # rendering the :show template. This is used within the
  # _direct_file_upload_hooks partial
  def show

    @has_file_upload = true

    set_model_object(@funding_application, current_user)

  end

  def update

    set_model_object(@funding_application, current_user)

    logger.info(
      'Updating signed_terms_and_conditions for funding_application ID: ' \
      "#{@funding_application.id}"
    )

    @model_object.validate_signed_terms_and_conditions = true

    if @model_object.update(funding_application_legal_sig_params)

      logger.info(
        'Finished updating signed_terms_and_conditions for funding_application ' \
        "ID: #{@funding_application.id}"
      )

      redirect_to :funding_application_upload_terms_and_conditions

    else

      logger.info(
        'Validation failed when attempting to update funding_application ' \
        "ID: #{@funding_application.id}"
      )

      log_errors(@model_object)

      render :show

    end

  end

  def upload

    set_model_object(@funding_application, current_user)

    if @model_object.signed_terms_and_conditions.attached?

      upload_signatories_and_evidence_to_sf(@funding_application)

      upload_signed_terms_and_conditions(@funding_application, @model_object)

      send_legal_signatory_link_emails(
        @funding_application, 
        @funding_application.legal_signatories.order(:created_at).second
      )

      # Assuming calls to Notify and Salesforce succeeded, set timestamps/logs.
      logger.info(
        "Updating signed_terms_submitted_on, agreement_submitted_on " \
          " and terms_agreed_at for " \
            "funding_applications_legal_sigs ID: #{@model_object.id}"
      )

      @funding_application.agreement.update(
        terms_agreed_at: DateTime.now
      )

      @model_object.update(
        signed_terms_submitted_on: DateTime.now
      )

      @funding_application.update(
        agreement_submitted_on: DateTime.now
      )

      logger.info(
        "Finished updating signed_terms_submitted_on, agreement_submitted_on " \
          " and terms_agreed_at for " \
            " funding_applications_legal_sigs ID: #{@model_object.id}"
      )
      
      redirect_to :funding_application_submitted

    else

      @model_object.errors.add(
        :signed_terms_and_conditions,
        t(
          'activerecord.errors.models.funding_applications_legal_sig.' \
          'attributes.signed_terms_and_conditions.invalid'
        )
      )

      logger.info(
        'No signed_terms_and_conditions found when attempting to submit ' \
        'signed terms and conditions for funding_applications_legal_sigs ' \
        "ID: #{@model_object.id}"
      )

      log_errors(@model_object)

      render :show

    end

  end

  private

  # Method responsible for setting the @model_object instance variable
  # for use by the view.
  # 
  # Called by the show, update and submit methods.
  #
  # @param funding_application [FundingApplication] An instance of
  #                                                 FundingApplication
  # @param applicant [User] An instance of User
  #
  # @return [LegalSignatory] signatory_is_applicant_join_row. Or nil
  #
  def set_model_object(funding_application, applicant)

    @model_object = get_when_signatory_is_applicant(funding_application, applicant)

  end

  def funding_application_legal_sig_params

    params.fetch(:funding_applications_legal_sig, {})
      .permit(:signed_terms_and_conditions)

  end

end
