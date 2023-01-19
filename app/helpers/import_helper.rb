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
  # @return [RestforceResponse] RestforceResponse A response object containing the 
  #                                                    the details required to import a project.
  #       
  def retrieve_imported_project_info(case_id)
    client =  get_import_salesforce_api_instance()
    client.retrieve_imported_project_info(case_id)
  end

  # Method call to API Client to retrieve existing contact information.
  #
  # @param [email] String Email of contact to  us a Salesforce look-up
  # @return [RestforceResponse] RestforceResponse A response object containing the 
  #                                                    the existing contact details if found. 
  #     
  # Not a great name, actually retrieves 1..* contacts as a query
  # on email_address
  # Consider moving to user helper
  def retrieve_existing_contact_info(email)
    client =  get_import_salesforce_api_instance()
    client.retrieve_existing_contact_info(email, current_user.id)
  end

  # import-todo rdoc
  # One contact returned.
  def retrieve_existing_salesforce_contact(salesforce_contact_id)
    client =  get_import_salesforce_api_instance()
    client.retrieve_existing_salesforce_contact(salesforce_contact_id)
  end

  # Method call to API Client to retrieve a matching salesforce organisation account
  # information.
  #
  # @param [organisation] Organisation organisation to retrieve SF account match
  # @return [RestforceResponse] RestforceResponse A response object containing the 
  #                                                    the existing organisation account details if found. 
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
  # @param [emails_match] Boolean do the user's email and salesforce contact email match
  # @param [orgs_match] Boolean do the user's organisation and salesforce account
  # @param [user_org] String String current user's organisation name
  # @param [user_org_postcode] String String current user's organisation postcode
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

    issue_importing_alert_email(
      support_mail_subject, 
      support_mail_body
    )

  end

end
