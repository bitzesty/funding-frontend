class FundingApplication::LegalAgreements::SignTermsController < ApplicationController
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

    set_award_type(@funding_application)

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

      redirect_to :funding_application_sign_terms_and_conditions

    else

      logger.info(
        'Validation failed when attempting to update funding_application ' \
        "ID: #{@funding_application.id}"
      )

      log_errors(@model_object)

      render :show

    end

  end

  def submit

    set_model_object(@funding_application, current_user)

    if @model_object.signed_terms_and_conditions.attached?

      logger.info(
        'Updating signed_terms_submitted_on for ' \
        "funding_applications_legal_sigs ID: #{@model_object.id}"
      )

      @funding_application.agreement.update(
        terms_agreed_at: DateTime.now
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
  
        logger.info(
          'Finished updating Legal_agreement_documents_submitted field ' \
          "in Salesforce for funding application ID: " \
          "#{@funding_application.id}"
        )
        
      end

      upload_signed_terms_and_conditions(@funding_application, @model_object)
      
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
  # which is then used in both the update and submit methods, and
  def set_model_object(funding_application, applicant)

    funding_application.funding_applications_legal_sigs.each do |fals|

      if applicant.email == fals.legal_signatory.email_address

        @model_object = fals
        break

      end

    end

  end

  def funding_application_legal_sig_params

    params.fetch(:funding_applications_legal_sig, {})
      .permit(:signed_terms_and_conditions)

  end

end
