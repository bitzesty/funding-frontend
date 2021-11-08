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

    set_award_type(funding_application) if funding_application.award_type_unknown?

    standard_terms_link =
      'https://www.heritagefund.org.uk/publications/standard-terms-grants' \
        '-3k-10k' if funding_application.is_3_to_10k?

    standard_terms_link =
      'https://www.heritagefund.org.uk/publications/standard-terms-grants' \
        '-10k-100k' if funding_application.is_10_to_100k?

    standard_terms_link =
      'https://www.heritagefund.org.uk/publications/standard-terms-grants' \
        '-100k-250k' if funding_application.is_100_to_250k?

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

    set_award_type(funding_application) if funding_application.award_type_unknown?

    receiving_a_grant_guidance_link =
      'https://www.heritagefund.org.uk/funding/receiving-grant-guidance' \
      '-ps3000-ps10000' if funding_application.is_3_to_10k?

    receiving_a_grant_guidance_link =
      'https://www.heritagefund.org.uk/funding/receiving-grant-guidance' \
        '-ps10000-ps100000' if funding_application.is_10_to_100k?

    receiving_a_grant_guidance_link =
      'https://www.heritagefund.org.uk/funding/receiving-grant-guidance' \
      '-ps100000-ps250000' if funding_application.is_100_to_250k?

    receiving_a_grant_guidance_link

  end

  # Method used to retrieve the link to the Retrieving a guidance on 
  # property ownership, 
  # based on the level of funding that has been awarded
  # @param funding_application [FundingApplication] An instance of
  #                                                 FundingApplication
  #
  # @return A string containing the link to the relevant guidance
  def get_receiving_guidance_property_ownership_link(funding_application)

    set_award_type(funding_application) if funding_application.award_type_unknown?

    link =
      'https://www.heritagefund.org.uk/funding/receiving-grant-guidance' \
      '-ps3000-ps10000#heading-8' if funding_application.is_3_to_10k?

    link =
      'https://www.heritagefund.org.uk/funding/receiving-grant-guidance' \
        '-ps10000-ps100000#heading-10' if funding_application.is_10_to_100k?

    link =
      'https://www.heritagefund.org.uk/funding/receiving-grant-guidance' \
      '-ps100000-ps250000#heading-10' if funding_application.is_100_to_250k?

    link

  end

  # Method used to retrieve the link to the Retrieving 
  # programme application guidance.
  # Initialises link to larger grant levels, overwrites if under 10k
  # based on the level of funding that has been awarded
  # @param funding_application [FundingApplication] An instance of
  #                                                 FundingApplication
  #
  # @return A string containing the link to the relevant guidance
  def get_programme_application_guidance_link(funding_application)

    set_award_type(funding_application) if funding_application.award_type_unknown?

    link =
      'https://www.heritagefund.org.uk/funding/' \
        'national-lottery-grants-heritage-10k-250k' 
      
    link =
      'https://www.heritagefund.org.uk/funding/' \
        'national-lottery-grants-heritage-2021/3-10k' \
          if funding_application.is_3_to_10k?

    link

  end


  # TODO: Noticed that salesforce_api.rb also has its own 
  # is_applicant_legal_signatory function.  Would be a quick 
  # change to have one function in application_helper.rb
  # however, requires a fair bit of testing.
  #
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

      if ls.email_address&.strip&.upcase == applicant.email&.strip&.upcase

        applicant_is_also_legal_signatory = true

        break

      end

    end

    applicant_is_also_legal_signatory

  end

  # Return true if grant award between 10000 and 100000
  #
  # @param grant award [Integer] Grant award amount
  #
  # @return result Boolean value indicating award falls in threshold
  def is_10001k_100000k_award(grant_award)
    
    if grant_award
      result = (grant_award > 10000) && (grant_award <= 100000)
    else
      result = false      
    end

    result 

  end

  # Return true if grant award between 100001 and 250000
  #
  # @param grant award [Integer] Grant award amount
  #
  # @return result Boolean value indicating award falls in threshold
  def is_100001k_250000k_award(grant_award)

    if grant_award
      result = (grant_award > 100000) && (grant_award <= 250000) if grant_award
    else
      result = false      
    end

    result 

  end

  # Sets an in memory enumerated type for the passed instance of
  # FundingApplication.  Used to dynamically determine what content
  # should be shown based on the category of award type.
  #
  # @param grant award [FundingApplication] an instance of this class
  def set_award_type(funding_application)

    funding_application.award_type = :award_type_unknown

    if funding_application.project.present? 
      funding_application.award_type = :is_3_to_10k

    elsif funding_application.open_medium.present?

      salesforce_api_client = SalesforceApiClient.new

      award_hash = 
        salesforce_api_client.get_payment_related_details \
          (funding_application.id) 

      funding_application.award_type = :is_10_to_100k \
        if is_10001k_100000k_award(award_hash[:grant_award])

      funding_application.award_type = :is_100_to_250k \
        if is_100001k_250000k_award(award_hash[:grant_award])

    end
      
    if funding_application.award_type_unknown?
      raise StandardError.new(
        "Could not identify an award type for: #{funding_application.id}"
      )
  
    end

  end

end
