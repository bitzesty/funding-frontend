module ImportHelper
  include ImportSalesforceApi
  include Mailers::ImportMailerHelper

  # Creates and returns an instance of ImportSalesforceApi
  # @return ImportSalesforceApi [ImportSalesforceApi] an instance of this class
  def get_import_salesforce_api_instance()
    import_salesforce_api_client = ImportSalesforceApiClient.new
  end
  
  # Method call to API Client to retrieve imported project information.
  #
  # @param [String] case_id A Case Id reference known to Salesforce
  # @return [RestforceResponse] RestforceResponse A response object
  #               containing the details required to import a project.
  #       
  def retrieve_imported_project_info(case_id)
    client =  get_import_salesforce_api_instance()
    client.retrieve_imported_project_info(case_id)
  end

  # Method call to API Client to retrieve existing contact information by
  # email.
  #
  # @param [email] String Email of contact to  us a Salesforce look-up
  # @return [RestforceResponse] RestforceResponse A response object
  #                      containing the existing contact details if found.
  #     
  def retrieve_existing_sf_contact_info_by_email(email)
    client =  get_import_salesforce_api_instance()
    client.retrieve_existing_sf_contact_info_by_email(email, current_user.id)
  end

  # Gets a salesforce contact by Salesforce contact Id
  # @param [salesforce_contact_id] String A Salesforce Contact Id
  # @return [RestforceResponse] RestforceResponse The contact details from SF
  def retrieve_existing_salesforce_contact(salesforce_contact_id)
    client =  get_import_salesforce_api_instance()
    client.retrieve_existing_salesforce_contact(salesforce_contact_id)
  end

  # Method call to API Client to retrieve a matching salesforce organisation
  # account information.
  #
  # @param [organisation] Organisation organisation to retrieve SF account
  # @return [RestforceResponse] RestforceResponse A response object containing
  #                        the existing organisation account details if found.
  #     
  # Consider moving to org helper
  def retrieve_matching_sf_orgs(organisation)
    client =  get_import_salesforce_api_instance() 
    client.retrieve_existing_account_info(
      organisation.name.gsub(/[']/,"\\\\'"),
      organisation.postcode,
      organisation.id
    )
  end

  # Method to construct email content for failed migrated project import
  # and call the import notify email helper. 
  #
  # @param [user_email] String Email of current user
  # @param [project_found] Boolean has the project been found
  # @param [case_id] String case id of project being imported
  # @param [project_ref] String project reference of project being imported
  # @param [emails_match] Boolean do the user's email and salesforce
  #                                                       contact email match
  # @param [orgs_match] Boolean do the user's organisation and salesforce
  #                                                         account match
  # @param [user_org] String String current user's organisation name
  # @param [user_org_postcode] String String current user's organisation
  #                                                                 postcode
  #     
  def send_issue_importing_alert_email(
    user_email, 
    project_found,
    case_id, 
    project_ref = nil,
    emails_match = nil, 
    orgs_match = nil, 
    user_org = nil, 
    user_org_postcode = nil
  )

    support_mail_subject = "Project reference number #{project_ref} could not be imported from Salesforce" 
    support_mail_body = ""

    if !project_found 

      support_mail_subject = "Project could not be imported from Salesforce"

      support_mail_body << "\nUser with email #{user_email} is trying to import a Salesforce case with Id #{case_id}. However, this Case Id does not exist in Salesforce.  The user may have amended the link. Or the case may have been removed from Salesforce. Please consider contacting the user for assistance."

    else
      if !emails_match
        support_mail_body << "\nProject #{project_ref} could not be imported for the following reason: A user with a Funding Frontend account registered to #{user_email} is trying to import Case Id #{case_id} which has a main contact with a different email address.  These email values should match.
        Please correct the problem in Salesforce, if possible.  And contact the user to ask them to try importing again."
      end

      if !orgs_match
        support_mail_body <<  "\nProject #{project_ref} could not be imported for the following reason: A user with a Funding Frontend account registered to #{user_email} is trying to import Case Id #{case_id}.  However, the organisation for the Funding Frontend account is #{user_org} and has the postcode #{user_org_postcode}.  This does not match the organisation details held in Salesforce.
        Please correct the problem in Salesforce, if possible.  And contact the user to ask them to try importing again."
      end

    end

    send_email_to_support(
      support_mail_subject, 
      support_mail_body
    )

  end

  # Returns true if the passed restforce collection contains a single
  # complete Salesforce contact.
  # Otherwise mails support with the issue to follow up, and returns
  # false
  #
  # @param [contact_restforce_collection] RestforceResponse A response
  #              object containing existing contact details, if found.
  # @return [mandatory_details_present] Boolean True if a single
  #                                             complete contact found.
  def single_complete_sf_contact_found(contact_restforce_collection)

    if contact_restforce_collection.size != 1

      send_multiple_contact_import_error_support_email(current_user.email)

      return false

    else

      con = contact_restforce_collection.first

      mandatory_details_present = salesforce_contact_complete?(con)

      send_incomplete_contact_import_error_support_email(
        current_user.email,
        concatenate_contact_name(con),
        choose_contact_phone(con),
        con&.MailingAddress
      ) unless mandatory_details_present

      return mandatory_details_present

    end

  end

  # Returns true if the passed contact contains mandatory info
  # complete Salesforce contact.
  # Otherwise mails support with the issue to follow up, and returns
  # false
  #
  # @param [con] RestforceResponse A response
  #              object containing contact details.
  # @return [mandatory_details_present] Boolean True if a single
  #                                             complete contact found.
  def salesforce_contact_complete?(con)

    con_address =  con&.MailingAddress

    mandatory_details_present =
      con_address&.street&.present? &&
        con_address&.city&.present? &&
          con_address&.postalCode&.present? &&
            choose_contact_phone(con).present? &&
              concatenate_contact_name(con).present?
  end

  # Takes a Salesforce Contact and translates the
  # various name fields into an appropriately
  # concatenated, trimmed single name string.
  #
  # @param [sf_contact] RestforceResponse A Contact record from Salesforce
  # @return [result] String The name formatted as a single string
  def concatenate_contact_name(sf_contact)

    result = [
        sf_contact.FirstName || '',
        sf_contact.MiddleName || '',
        sf_contact.LastName || ''
      ].reject(&:empty?).join(' ')

  end

  # Takes a Salesforce Contact and select the
  # phone number giving priority to home over mobile
  # number.
  #
  # @param [sf_contact] RestforceResponse A Contact record from Salesforce
  # @return [sf_contact.Phone] String The chosen phone number or blank string
  def choose_contact_phone(sf_contact)

    sf_contact.Phone.present? ? sf_contact.Phone :
      (sf_contact.MobilePhone || '') # get mobile if no phone.

  end

  # Sends an email to the supoort team when FFE finds > 1 matching Salesforce
  # contact with a matching email address.
  # @param [user_email] String Email for the current user
  def send_multiple_contact_import_error_support_email(user_email)  

    support_mail_body = ""
    support_mail_subject = "Multiple matching contacts found in Salesforce for email #{user_email}."

    support_mail_body << "\nA user with email #{user_email} is trying to register a Funding Frontend account. Multiple matching contacts with the same email address have been found in Salesforce. Please refer to the job instructions for correcting this. Once the corrections are made, please ask the user to sign in again."

      send_email_to_support(
        support_mail_subject,
        support_mail_body
      )

  end

  # Sends an email to the supoort team when FFE finds 1 matching Salesforce
  # contact but some mandatory details for that contact are missing.
  # @param [user_email] String Email for the current user
  # @param [con_name] String Salesforce name for the contact
  # @param [con_phone] String Salesforce phone for the contact
  # @param [con_address] Restforce::Mash Salesforce address for the contact
  def send_incomplete_contact_import_error_support_email(
    user_email,
    con_name,
    con_phone,
    con_address
  )

    missing_fields = ""
    support_mail_body = ""

    missing_fields.concat("Contact name empty \n") unless con_name.present?
    missing_fields.concat("Contact phone number empty \n") unless con_phone.present?

    missing_fields.concat("Contact street empty \n") unless con_address&.street&.present?
    missing_fields.concat("Contact city empty \n") unless con_address&.city&.present?
    missing_fields.concat("Contact postcode empty \n") unless con_address&.postalCode&.present?
  
    support_mail_subject = "Matching contact found in Salesforce, but info missing for email #{user_email}."

    support_mail_body <<  "\nA user with email #{user_email} is trying to register a Funding Frontend account. A matching Salesforce contact has been found, but the following information is missing: \n\n"

    support_mail_body << missing_fields

    support_mail_body << "\n\nPlease complete the missing information for the contact. After that has been done, please ask the user to sign in again."

    send_email_to_support(
      support_mail_subject,
      support_mail_body
    )

  end

  # Sends an email to the supoort team when FFE finds > 1 different Salesforce
  # Accounts with the given name, postcode combination.
  # @param [user_email] String Email for the current user
  # @param [org_name] String Email for the current user
  # @param [org_postcode] String Email for the current user
  def send_multiple_account_import_error_support_email(
    user_email, org_name, org_postcode)

    support_mail_body = ""
    support_mail_subject = "Multiple organisations found in Salesforce with name #{org_name} and postcode #{org_postcode} and they have differences."

    support_mail_body << "\nA user with email #{user_email} is trying to start a new application or pre-application. However, multiple organisations have been found with the name #{org_name} and postcode #{org_postcode} in Salesforce and they have differences. Please refer to the job instructions for correcting this. Once the corrections are made, please ask the user to try applying again."

      send_email_to_support(
        support_mail_subject,
        support_mail_body
      )

  end

  # Sends an email to the supoort team when FFE finds 1 or more
  # matching salesforce accounts, with the given name, postcode combination.
  # But they are missing some essential information.
  # @param [user_email] String Email for the current user
  # @param [org_name] String Email for the current user
  # @param [org_postcode] String Email for the current user
  # @param [organisation] Organisation Instance of an organisation
  def send_incomplete_account_import_error_support_email(user_email,
    organisation)

    # organisation.name.present?,
    # organisation.line1.present?,
    # organisation.townCity.present?,
    # organisation.postcode.present?,

    missing_fields = ""
    support_mail_body = ""

    missing_fields.concat("Organisation name empty \n") unless organisation.name.present?
    missing_fields.concat("Organisation street empty \n") unless organisation.line1.present?
    missing_fields.concat("Organisation city empty \n") unless organisation.townCity.present?
    missing_fields.concat("Organisation postcode empty \n") unless organisation.postcode.present?

    support_mail_body = ""
    support_mail_subject = "Incomplete organisations found in Salesforce with name #{organisation.name} and postcode #{organisation.postcode}."

    support_mail_body << "\nA user with email #{user_email} is trying to apply in Funding Frontend. Matching Salesforce organisation(s) have been found for organisation name #{organisation.name} and postcode #{organisation.postcode}, but the following information is missing: \n\n"

    support_mail_body << missing_fields

    support_mail_body << "\n\nPlease complete the missing information for all occurrences of this Organisation in Salesforce. After that has been done, please ask the user to try applying again."

      send_email_to_support(
        support_mail_subject,
        support_mail_body
      )

    end

    # Sets the award type of a funding application based on the SF case 
    # record type.
    # matching salesforce accounts, with the given name, postcode combination.
    # But they are missing some essential information.
    # @param [funding_application] FundingApplication to set the award type on.
    # @param [salesforce_case_record_type] String record type in salesforce.
    def set_migrated_award_type(
      funding_application,
      salesforce_case_record_type
    )

      if salesforce_case_record_type == 'Migrated_Large_Delivery'
        funding_application.update!(award_type: :migrated_large_delivery)
      end

    end

end
