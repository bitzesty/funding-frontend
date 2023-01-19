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

      # TODO: IF FUNDING APPLICATION ALREADY EXISTS (PREVIOUSLY IMPORTED)
      # THEN DO NOT IMPORT
      Rails.logger.info("User id #{current_user.id} has confirmed that the "\
         "details for project reference number "\
            "#{@salesforce_info_for_page.Project_Reference_Number__c} " \
              "with Case ID: #{@salesforce_info_for_page.Id} are correct at " \
                " #{DateTime.now}.")
  
      populate_empty_user(current_user, @salesforce_info_for_page.ContactId)
      populate_empty_org(current_user, @salesforce_info_for_page.AccountId)

      redirect_to :authenticated_root

    else 
      @user_can_import = user_can_import(@salesforce_info_for_page)
      render :show
    end

  end

  private

  def get_params
    params.fetch(:funding_application, {}).permit(
      :migrated_details_correct
    )
  end

  # Method to populate current users details with those held in SF,
  # if their details are not already complete.
  #
  # @param [current_user] User current user logged in.
  # @param [salesforce_contact_id] String Salesforce contact ID of user
  #    
  def populate_empty_user(current_user, salesforce_contact_id)

    unless user_details_complete(current_user)

      @user_was_imported = true

      populate_user_from_salesforce(current_user, salesforce_contact_id)

    end

  end

  # Method to populate current organisation details with those held in SF,
  # if the organisation details do not exist. 
  #
  # @param [current_user] User current user logged in.
  # @param [salesforce_contact_id] String Salesforce contact ID of user
  #    
  def populate_empty_org(current_user, salesforce_account_id)

    create_organisation_if_none_exists(current_user)

    org = current_user.organisations.first

    unless complete_organisation_details?(org)

      @org_was_imported = true

      populate_migrated_org_from_salesforce(
        org,
        salesforce_account_id
      )

    end

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

end
