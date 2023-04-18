class Import::IsThisYourProjectController < ApplicationController
  before_action :authenticate_user!
  include ImportHelper
  include UserHelper
  include OrganisationHelper

  # Import is allowed if the contact emails match between FFE and SF &&
  # The organisation details match between FFE and SF.
  # Org check initialised to true, for when no FFE org details exist.
  # This is because (if the emails match) we will pop orgs from SF.
  def show

    @funding_application = FundingApplication.new

    @salesforce_info_for_page =
      retrieve_imported_project_info(params.fetch(:salesforce_case_id))

     @project_found = @salesforce_info_for_page.present?

    if @project_found
      @user_can_import = user_can_import(@salesforce_info_for_page)
    else
      @user_can_import = false
    end

    send_issue_importing_alert_email(
      current_user.email, 
      @project_found, 
      @salesforce_info_for_page&.Id,
      @salesforce_info_for_page&.Project_Reference_Number__c, 
      @emails_match, 
      @orgs_match, 
      current_user.organisations.first&.name,
      current_user.organisations.first&.postcode
      ) if !@user_can_import

  end


  def update

    @funding_application = FundingApplication.new

    @salesforce_info_for_page =
      retrieve_imported_project_info(params.fetch(:salesforce_case_id))

    @funding_application.validate_migrated_details_correct = true

    @funding_application.migrated_details_correct =
      get_params[:migrated_details_correct]

    if @funding_application.valid?

      Rails.logger.info("User id #{current_user.id} has confirmed that the "\
         "details for project reference number "\
            "#{@salesforce_info_for_page.Project_Reference_Number__c} " \
              "with Case ID: #{@salesforce_info_for_page.Id} are correct at " \
                " #{DateTime.now}.")
  
      # Orchestrate populating current_user from Salesforce Contact if required
      unless orchestrate_user_import_ok?(@salesforce_info_for_page.ContactId)
        redirect_to user_existing_details_error_path and return
      end

      # Orchestrate populating user's org from Salesforce Account if required
      unless orchestrate_organisation_import_ok?(@salesforce_info_for_page.AccountId)
        redirect_to organisation_existing_organisations_error_path(
          current_user.organisations.first.id
        ) and return
      end

      orchestrate_funding_application_import(@salesforce_info_for_page)

    else 
      @user_can_import = user_can_import(@salesforce_info_for_page)
      render :show and return
    end

    redirect_to :authenticated_root

  end

  private

  def get_params
    params.fetch(:funding_application, {}).permit(
      :migrated_details_correct
    )
  end

  # Check that the user and organisations match between FFE and SF
  # @param [salesforce_info_for_page] Restforceresponse A collection
  #                                           of project info from SF
  # @return [user_can_import] Boolean true if the user can import
  #
  def user_can_import(salesforce_info_for_page)

    if salesforce_info_for_page.nil?
      logger.error(
        "User: #{current_user.id} used an 'is-this-your-project link' that " \
          "used a case id not known to Salesforce"
      )
      return false
    end
 
    # Check that the contact matches the one on project
    @emails_match = (current_user.email.strip.downcase ==
      salesforce_info_for_page&.ContactEmail&.strip&.downcase)

    # If Contact email check OK, then check org.
    @orgs_match = true # initialise
    # If postcode exists, then organisation details may have been started.
    if @emails_match && current_user.organisations.first&.postcode.present?

      ffe_org = current_user.organisations.first
      sf_org = salesforce_info_for_page&.Account

      @orgs_match =
        (ffe_org.name&.strip&.downcase ==
          sf_org&.Name&.strip&.downcase) &&
            (ffe_org.postcode&.strip&.downcase ==
                sf_org&.BillingPostalCode&.strip&.downcase)
    end

    logger.error(
      "Case: #{@salesforce_info_for_page.Id} cannot be imported to user: " \
        "#{current_user.id} because FFE and SF organisation details " \
          "do not match."
    ) unless @orgs_match

    logger.error(
      "Case: #{@salesforce_info_for_page.Id} cannot be imported to user: " \
        "#{current_user.id} because FFE and SF main contact emails " \
          "do not match."
    ) unless @emails_match

    user_can_import = @emails_match && @orgs_match

  end

  # 1) Gets the Contact record from Salesforce
  # 2) Checks if the Contact record is complete
  #   a) If the Contact record is complete, populates User, People, Addresses.
  #   b) If Contact record incomplete, mails support and serves error page.
  #
  # @param [salesforce_contact_id] String Id of Salesforce Contact record
  # @return [result] Boolean True if orchestration successful
  def orchestrate_user_import_ok?(salesforce_contact_id)

    result = user_details_complete(current_user) # Initialise.

    unless user_details_complete(current_user)

      contact_from_salesforce =
        retrieve_existing_salesforce_contact(salesforce_contact_id)

      if salesforce_contact_complete?(contact_from_salesforce)

        populate_user_from_restforce_object(
          current_user,
          contact_from_salesforce
        )

        replicate_user_attributes_to_associated_person(current_user)
        check_and_set_person_address(current_user)

        Rails.logger.info("Funding Frontend User id: #{current_user.id} " \
          "has a reusable contact in Salesforce. Importing Contact " \
            "#{salesforce_contact_id} from " \
              "Salesforce as part of Project import.")

        result = true

      else

        send_incomplete_contact_import_error_support_email(
          current_user.email,
          concatenate_contact_name(contact_from_salesforce),
          choose_contact_phone(contact_from_salesforce),
          contact_from_salesforce&.MailingAddress
        )

        Rails.logger.info("Funding Frontend User id: #{current_user.id} " \
          "COULD NOT reuse contact from Salesforce. Contact Id: " \
            "#{salesforce_contact_id}. " \
              "Error during import.")

        result = false

      end

    end

    result

  end

  # Method to populate current organisation details with those held in SF,
  # Once the organisation has been populated from Salesforce, the organisation
  # is checked for completeness.  If the organisation is incomplete, then its
  # information is cleared.  This is so the missing info can be supplied in
  # Salesforce by the Support Team, then the FFE user can try again later.
  #
  # @param [current_user] User current user logged in.
  # @param [salesforce_account_id] String Salesforce contact ID of user
  # @return [result] Boolean True if orchestration successful
  #
  def orchestrate_organisation_import_ok?(salesforce_account_id)

    create_organisation_if_none_exists(current_user)

    org = current_user.organisations.first

    result = complete_organisation_details?(org) # Initialise.

    unless complete_organisation_details?(org)

      result = populate_migrated_org_from_salesforce(
        org,
        salesforce_account_id
      )

    end

    # check that newly populated organisation is complete, clear if not.
    unless complete_organisation_details?(org)
      result = false
      clear_org_data(org)
    end

    # User has created org that matches, however haas no SF acc ID as they have not submitted
    if org.salesforce_account_id.blank?
      org.salesforce_account_id = salesforce_account_id 
      org.save!
    end

    result

  end

  # Method to create a new funding application from the project details
  # retrieved from salesforce. If a funding application has not already been 
  #  created from these details then a new funding application is created
  #  and associated to the current user's organisation. Otherwise, the 
  #  the existing funding application with matching salesforce case id 
  #  is returned.
  #
  # @param [project_import_details] <Restforce::SObject>
  #    details of project to import
  #
  def orchestrate_funding_application_import(project_import_details)

    funding_application = FundingApplication.find_by(
      salesforce_case_id: project_import_details.Id
    )

    Rails.logger.info("orchestrate_funding_application_import found " \
      "funding application with id: #{funding_application}. " \
        "No further action taken.") if funding_application.present?

    if funding_application.nil?

      funding_application = FundingApplication.create(
        organisation_id: current_user.organisations.first.id,
        salesforce_case_id: project_import_details.Id,
        submitted_on: project_import_details.Submission_Date_Migrated__c,
        project_reference_number: project_import_details.Project_Reference_Number__c,
        agreement_submitted_on: project_import_details.Permission_to_start_date__c
      )

      funding_application.update!(status: :payment_can_start) \
        if funding_application.agreement_submitted_on.present?

      # we know the award type from Salesforce, translate to FFE equivalent
      set_migrated_award_type(
        funding_application,
        project_import_details.RecordType.DeveloperName
      )

      Rails.logger.info("orchestrate_funding_application_import created " \
        "funding application with id: #{funding_application}. ")

    end

  end

end
