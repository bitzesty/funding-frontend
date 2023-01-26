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
      organisation.name,
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
  def single_complete_sf_contact_found(contact_restforce_collection)

    if contact_restforce_collection.size != 1

      send_multiple_contact_import_error_support_email(current_user.email)

      return false

    else

      con = contact_restforce_collection.first

      con_name = (con.FirstName || '') +
        (con.MiddleName || '') + (con.LastName || '')

      con_phone = (con.Phone || '') + (con.MobilePhone || '')

      con_address =  con&.MailingAddress

      mandatory_details_present =
        con_address&.street&.present? &&
          con_address&.city&.present? &&
            con_address&.postalCode&.present? &&
              con_phone.present? &&
                con_name.present?

      send_incomplete_contact_import_error_support_email(
        current_user.email,
        con_name, 
        con_phone, 
        con_address
      ) unless mandatory_details_present

      return mandatory_details_present

    end

  end

  # Sends an email to the supoort team when FFE finds > 1 matching Salesforce
  # contact with a matching email address.
  # @param [user_email] String Email for the current user
  def send_multiple_contact_import_error_support_email(user_email)  

    support_mail_body = ""
    support_mail_subject = "Multiple matching contacts found in Salesforce for email #{user_email}."

    support_mail_body << "\nA user with email #{user_email} is trying to register a Funding Frontend account. Multiple matching contacts with the same email address have been found in Salesforce. Please refer to the job instructions for correcting this. Once the corrections are made, please ask the user to try the account registration process again."

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

    support_mail_body << "\n\nPlease complete the missing information for the contact. After that has been done, please ask the user to try the account registration process again."

    send_email_to_support(
      support_mail_subject,
      support_mail_body
    )

  end

end
