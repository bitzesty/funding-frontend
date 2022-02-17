require 'bcrypt'

module LegalAgreementsHelper
  include SalesforceApi
  include AgreementSalesforceApi
  include Mailers::SigMailerHelper

  # Method to determine whether or not an encoded_signatory_id matches an
  # existing LegalSignatory UUID for a given FundingApplication
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  # @param [String] encoded_signatory_id A URI encoded version of an encrypted
  #                                      LegalSignatory UUID
  # @return [Boolean] True if a matching LegalSignatory was found, otherwise
  #                   False
  def encoded_signatory_id_verifies?(funding_application, encoded_signatory_id)
    get_signatory_from_encoded_id(
      funding_application,
      encoded_signatory_id
    ).present?
  end

  # Method to retrieve a LegalSignatory if the encoded_signatory_id provided,
  # when decoded, matches the GUID of a LegalSignatory associated with the
  # given FundingApplication
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  # @param [String] encoded_signatory_id A URI encoded version of an encrypted
  #                                     LegalSignatory UUID
  # @return [LegalSignatory] An instance of LegalSignatory
  def get_signatory_from_encoded_id(funding_application, encoded_signatory_id)

    result = nil
    
    # At this point, the encoded_signatory_id is a URI encoded string
    base64_encoded_signatory_id = URI.decode(encoded_signatory_id)

    # After URI decoding, we are left with a Base64 encoded string
    encrypted_signatory_id = Base64.decode64(base64_encoded_signatory_id)

    funding_application.legal_signatories.each do |signatory|
        
      if verified_signatory_id?(encrypted_signatory_id, signatory)

        result = signatory
        break
      
      end
        
    end

    result

  end

  # Method to determine whether or not a specified encrypted_signatory_id
  # matches a spcified LegalSignatory's GUID
  #
  # @param [String] encrypted_signatory_id A LegalSignatory UUID which has been
  #                                        encrypted by BCrypt
  # @param [LegalSignatory] legal_signatory An instance of a LegalSignatory
  # @return [Boolean] A Boolean to signify whether a specified
  #                   encrypted_signatory_id matched a specified
  #                   LegalSignatory's GUID
  def verified_signatory_id?(encrypted_signatory_id, legal_signatory)
      
    result = false

    begin

      # This verifies the encrypted_signatory_id. BCrypt overrides ==
      result =
        BCrypt::Password.new(encrypted_signatory_id) == legal_signatory.id

    rescue BCrypt::Errors::InvalidHash => e

        Rails.logger.info(
          'verified_signatory_id? encountered invalid hash ' \
          "#{encrypted_signatory_id} when checking against legal_signatory " \
          "ID: #{legal_signatory.id}"
        )
      
      end

      result

  end

  # Method used to encode the UUID of a LegalSignatory
  #
  # @param [String] legal_signatory_id The UUID of a LegalSignatory
  #
  # @return [String] An encoded UUID for a LegalSignatory which can be
  #                  injected into a URL 
  def encode_legal_signatory_id(legal_signatory_id)

    logger.debug(
      "Encrypting LegalSignatory ID: #{legal_signatory_id}"
    )

    encrypted = BCrypt::Password.create(legal_signatory_id)

    logger.debug(
      "Base64 encoding LegalSignatory ID: #{legal_signatory_id}"
    )

    base64_encoded = Base64.encode64(encrypted)

    logger.debug(
      "URI encoding LegalSignatory ID: #{legal_signatory_id}"
    )

    URI.encode(base64_encoded)

  end

  # Loops through FundingApplicationLegalSignatories
  # returns false if any haven't signed terms submitted
  #
  # @param [FundingApplication] funding_application 
  #
  # @return [Boolean] result True if all legal 
  #                   signatories have submitted signed terms, else false.
  def all_signatories_have_submitted_terms?(funding_application)
    
    result = true

    funding_application.funding_applications_legal_sigs.each do |fals|
      
      if fals.signed_terms_submitted_on.nil?

        result = false
        break

      end

    end
    
    result

  end

  # Method responsible for setting a checkbox field in Salesforce 
  #
  # @param funding_application [FundingApplication] An instance of
  #                                                 FundingApplication
  def update_legal_agreement_documents_submitted(funding_application)

    client = SalesforceApiClient.new
    case_id = funding_application.salesforce_case_id
    client.update_legal_agreement_documents_submitted(case_id)

  end

  # Method responsible for orchestrating the upload of
  # additional_evidence_files to Salesforce
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  def upload_additional_evidence_files(funding_application)

    client = SalesforceApiClient.new

    case_id = funding_application.salesforce_case_id

    client.upload_additional_evidence_files(
      funding_application.additional_evidence_files,
      'Additional Evidence Files',
      funding_application.salesforce_case_id
    )

  end

  # Method responsible for orchestrating the upload of
  # a signed_terms_and_conditions file to Salesforce
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  # @param [FundingApplicationsLegalSig] funding_applications_legal_sig
  #                          An instance of FundingApplicationsLegalSig
  def upload_signed_terms_and_conditions(
    funding_application,
    funding_applications_legal_sig
  )

    client = SalesforceApiClient.new

    case_id = funding_application.salesforce_case_id

    client.upload_signed_terms_and_conditions(
      funding_applications_legal_sig.signed_terms_and_conditions,
      'Signed Terms and Conditions: ' \
        "(#{funding_applications_legal_sig.legal_signatory.name})",
      funding_application.salesforce_case_id
    )

  end

  # Method responsible for orchestrating the retrieval of
  # additional grant conditions from Salesforce
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  # @param [FundingApplicationsLegalSig] funding_applications_legal_sig
  #                          An instance of FundingApplicationsLegalSig
  def additional_grant_conditions(funding_application)

    client = SalesforceApiClient.new

    case_id = funding_application.salesforce_case_id

    additional_grant_conditions =
      client.additional_grant_conditions \
        (funding_application.salesforce_case_id)

  end

  # Method responsible for retreiving a subset of Salesforce 
  # information for a project
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  # @return [<Restforce::SObject] project details. A collection 
  #                                               containing project details.
  def project_details(funding_application)

    client = SalesforceApiClient.new

    project_details =
      client.project_details \
        (funding_application.salesforce_case_id)

  end

  # Method responsible for orchestrating emails with a Legal Signatories link
  # which when clicked, allows a sig to upload signed terms and conditions.
  #
  # Begins by creating a signatory link.
  # Then an email is sent to a signatory and a copy is sent to support.
  #
  # @param [FundingApplication] funding_application An instance of
  #                             FundingApplication
  # @param [LegalSignatory] legal_signatory An instance of LegalSignatory
  def send_legal_signatory_link_emails(funding_application, legal_signatory)

    encoded_signatory_id = encode_legal_signatory_id(legal_signatory.id)

    agreement_link = build_agreement_link(
      funding_application.id,
      encoded_signatory_id
    )

    # send to applicant
    send_legal_signatory_email(legal_signatory.email_address, 
        funding_application, agreement_link, ".")

    
    logger.info "Sig link mail sent to #{legal_signatory.email_address} " \
      "for legal_signatory.id #{legal_signatory.id} and "
        "for funding_application ID: #{@funding_application.id}"

    # copy to support
    send_legal_signatory_email(
      Rails.configuration.x.no_reply_email_address,
      funding_application, agreement_link, 
      " FAO - #{legal_signatory.email_address}"
    )

    logger.info "Support link mail sent to "
      "#{Rails.configuration.x.no_reply_email_address} " \
        "for legal_signatory.id #{legal_signatory.id} and "
          "for funding_application ID: #{@funding_application.id}"

  end

  # Method that implements notify mailer to send 
  # signatory emails containing magic link
  #
  # @param [String] email_address Email address of signatory. 
  # @param [FundingApplication] funding_application FundingApplication 
  # that requires legal signatures
  # @param [String] agreement_link URL encoded agreement link to be emailed
  # @param [String] fao_email email to attach to subject if sent to support.
  #
  # @return [String] The URL to the 'Check project details' page
  def send_legal_signatory_email(email_address, funding_application, 
    agreement_link, fao_email)

    send_mail_with_signatory_link(
      email_address,
      funding_application.id,
      agreement_link,
      funding_application.project.present? ?
        funding_application.project.project_title :
        funding_application.open_medium.project_title,
      funding_application.project_reference_number,
      funding_application.organisation.name,
      fao_email
    )

  end


  # Method responsible for building a URL to 'Check project details' page
  # of the legal agreement journey for a Legal Signatory
  #
  # @param [String] funding_application_id UUID for a FundingApplication
  # @param [String] encoded_signatory_id An encoded UUID for a LegalSignatory
  #
  # @return [String] The URL to the 'Check project details' page
  def build_agreement_link(funding_application_id, encoded_signatory_id)

    url_for(
      controller: 
        '/funding_application/legal_agreements/signatories/check_details',
      encoded_signatory_id: encoded_signatory_id,
      action: 'show',
    )

  end


  def upload_signatories_to_salesforce(funding_application)

    client = AgreementSalesforceApiClient.new
    
    @funding_application.legal_signatories.each do |ls|
      ls.salesforce_legal_signatory_id = 
        client.upsert_signatory_to_salesforce(ls, funding_application)
      ls.save!
    end

  end

end
