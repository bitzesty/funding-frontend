module FundingApplicationHelper
  include SalesforceApi

  # Method responsible for orchestrating the submission of a funding
  # application to Salesforce
  #
  # @param [FundingApplication] funding_application An instance of a
  #                                                 FundingApplication
  # @param [User] user An instance of a User
  # @param [Organisation] organisation An instance of an Organisation
  def send_funding_application_to_salesforce(
    funding_application,
    user,
    organisation
  )

    salesforce_api_client = SalesforceApiClient.new

    salesforce_references = salesforce_api_client.create_project(
      funding_application,
      user,
      organisation
    )

    funding_application.update(
      submitted_on: DateTime.now,
      salesforce_case_id: salesforce_references[:salesforce_project_reference],
      project_reference_number: salesforce_references[:external_reference],
      salesforce_case_number: salesforce_references[:external_reference].nil? ?
        nil :
        salesforce_references[:external_reference].chars.last(5).join
    )

    user.update(
      salesforce_contact_id: salesforce_references[:salesforce_contact_id]
    ) if user.salesforce_contact_id.nil?

    organisation.update(
      salesforce_account_id: salesforce_references[:salesforce_account_id]
    ) if organisation.salesforce_account_id.nil?

  end

  # Method used to retrieve the link to the Standard Terms of Grant
  # based on the level of funding that has been awarded
  # @param funding_application [FundingApplication] An instance of
  #                                                 FundingApplication
  #
  # @return A string containing the link to the relevant Standard Terms
  #         of Grant
  def get_standard_terms_link(funding_application)

    standard_terms_link =
      'https://www.heritagefund.org.uk/publications/standard-terms-grants' \
      '-3k-10k' if funding_application.project.present?

    if funding_application.open_medium.present?

      # TODO: Get grant awarded value from Salesforce
      #       and use this to determine the links

      # if grant_award >= 10000 & grant_award <= 100000

        # standard_terms_link =
        #   'https://www.heritagefund.org.uk/publications/standard-terms-grants' \
        #   '-10k-100k'

      # elsif grant_award > 100000

        # standard_terms_link =
        #   'https://www.heritagefund.org.uk/publications/standard-terms-grants' \
        #   '-100k-250k'

      # end

      standard_terms_link = ''

    end

    standard_terms_link

  end

  # Method used to retrieve the link to the Retrieving a Grant guidance
  # based on the level of funding that has been awarded
  # @param funding_application [FundingApplication] An instance of
  #                                                 FundingApplication
  #
  # @return A string containing the link to the relevant Retrieving a
  #         Grant guidance
  def get_receiving_a_grant_guidance_link(funding_application)

    receiving_a_grant_guidance_link =
      'https://www.heritagefund.org.uk/funding/receiving-grant-guidance' \
      '-ps3000-ps10000' if funding_application.project.present?

    if funding_application.open_medium.present?

      # TODO: Get grant awarded value from Salesforce
      #       and use this to determine the links

      # if grant_award >= 10000 & grant_award <= 100000

        # receiving_a_grant_guidance_link =
        #   'https://www.heritagefund.org.uk/funding/receiving-grant-guidance' \
        #   '-ps10000-ps100000'

      # elsif grant_award > 100000

        # receiving_a_grant_guidance_link =
        #   'https://www.heritagefund.org.uk/funding/receiving-grant-guidance' \
        #   '-ps100000-ps250000'

      # end

      receiving_a_grant_guidance_link = ''

    end

    receiving_a_grant_guidance_link

  end

  # Method used to determine whether or not the applicant
  # is also a legal signatory for a given funding application
  #
  # @param funding_application [FundingApplication] An instance of
  #                                                 FundingApplication
  # @param applicant [User] An instance of User
  #
  # @return A Boolean value indicating whether or not the applicant
  #         is also a legal signatory for the given funding application
  def is_applicant_legal_signatory?(funding_application, applicant)

    applicant_is_also_legal_signatory = false

    funding_application.organisation.legal_signatories.each do |ls|

      if ls.email_address == applicant.email

        applicant_is_also_legal_signatory = true

        break

      end

    end

    applicant_is_also_legal_signatory

  end

end
