class FundingApplication::LegalAgreements::Signatories::UploadTermsController < ApplicationController
  include LegalAgreementsContext
  include LegalAgreementsHelper
  include ObjectErrorsLogger
  include FundingApplicationHelper

  # This method is used to set the @has_file_upload instance variable before
  # rendering the :show template. This is used within the
  # _direct_file_upload_hooks partial
  def show

    @has_file_upload = true

    set_model_object(@funding_application, params[:encoded_signatory_id])

    @download_link = 
      '/terms_and_conditions/Signatory only National Lottery Heritage Fund terms and ' \
        'conditions for £3,000 to £10,000.docx' \
          if @funding_application.is_3_to_10k?
         
    
    @download_link = 
      '/terms_and_conditions/Signatory only National Lottery Heritage ' \
        'Fund terms and conditions for £10,000 to £100,000.docx' \
          if @funding_application.is_10_to_100k?
          
    
    @download_link = 
      '/terms_and_conditions/Signatory only National Lottery Heritage ' \
        'Fund terms and conditions for £100,000 to £250,000.docx' \
          if @funding_application.is_100_to_250k?          

  end

  def update

    set_model_object(@funding_application, params[:encoded_signatory_id])

    logger.info(
      'Updating signed_terms_and_conditions for funding_application ID: ' \
      "#{@funding_application.id}"
    )

    @model_object.validate_signed_terms_and_conditions = true

    if @model_object.update(funding_application_legal_sig_params)

      logger.info(
        'Finished updating signed_terms_and_conditions for ' \
        "funding_application ID: #{@funding_application.id}"
      )

      redirect_to :funding_application_signatories_upload_terms_and_conditions

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

    set_model_object(@funding_application, params[:encoded_signatory_id])

    if @model_object.signed_terms_and_conditions.attached?

      funding_application_legal_signatory = 
        set_model_object(@funding_application, params[:encoded_signatory_id])

      upload_signed_terms_and_conditions(@funding_application, @model_object)

      logger.info(
        'Updating signed_terms_submitted_on for ' \
        "funding_applications_legal_sigs ID: #{@model_object.id}"
      )

      @model_object.update(
        signed_terms_submitted_on: DateTime.now
      )

      logger.info(
        'Finished updating signed_terms_submitted_on for ' \
        "funding_applications_legal_sigs ID: #{@model_object.id}"
      )

      if all_signatories_have_submitted_terms?(@funding_application)

        logger.info(
          'Updating Legal_agreement_documents_submitted	field ' \
          "in Salesforce for funding applications ID: " \
          "#{@funding_application.id}"
        )
        
        update_legal_agreement_documents_submitted(@funding_application)

        remove_personal_data_from_signatories(@funding_application)

        logger.info(
          'Finished updating Legal_agreement_documents_submitted field ' \
          "in Salesforce for funding application ID: " \
          "#{@funding_application.id}"
        )
        
      end

      redirect_to :funding_application_signatories_submitted

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
  # which is then used in both the update and submit methods.
  # In this case the model object is and instance of FundingApplicationsLegalSig 
  def set_model_object(funding_application, encoded_signatory_id)

    signatory = get_signatory_from_encoded_id(
      funding_application,
      encoded_signatory_id
    )

    @model_object = FundingApplicationsLegalSig.find_by(
      legal_signatory_id: signatory.id,
      funding_application_id: funding_application.id
    )

  end

  def funding_application_legal_sig_params

    params.fetch(:funding_applications_legal_sig, {})
      .permit(:signed_terms_and_conditions)

  end

end