class AdminPortal::UpdateOrganisationDetailsController < ApplicationController
  include AdminPortalContext
  include OrganisationHelper
  include Auditor

  NOT_FOUND_ERR = 'Salesforce Organisation Id not found'

  INCOMPLETE_ERR = "Organisation details are incomplete in Salesforce. " \
    "Check Organisation Name, Billing Street, Billing City " \
      "and Billing Zip/Postal Code"


  def show
    retrieve_page_info
  end

  def update

    @errors = []

    organisation_to_refresh = Organisation.find(params[:organisation_id])

    @salesforce_account_id = get_salesforce_account_id(organisation_to_refresh)

    organisation_from_salesforce =
      get_organisation_from_salesforce(@salesforce_account_id)

    if organisation_from_salesforce.blank?

      not_found_log = "Funding Frontend Organisation id: " \
        "#{organisation_to_refresh.id} " \
          "COULD NOT refresh from Salesforce. Account Id: " \
            "#{@salesforce_account_id} not found."

        log_error_and_show(not_found_log, NOT_FOUND_ERR)

    else
      # Check if salesforce restforce org details are complete
      unless check_org_in_sf_complete?(organisation_from_salesforce)

        incomplete_log =  "Funding Frontend Organisation id: " \
          "#{organisation_to_refresh.id} " \
            "COULD NOT refresh from Salesforce. Account Id: " \
              "#{@salesforce_contact_id} is incomplete."

        log_error_and_show(incomplete_log, INCOMPLETE_ERR)

      else

        Rails.logger.info("Funding Frontend Organisation id: " \
          "#{organisation_to_refresh.id} " \
            "being refreshed from #{@salesforce_account_id}.")

        populate_organisation_from_restforce_object(
          organisation_to_refresh,
          organisation_from_salesforce
        )

        organisation_to_refresh.org_type = :unknown
        organisation_to_refresh.salesforce_account_id = @salesforce_account_id

        save_org_and_audit(organisation_to_refresh) if
          organisation_to_refresh.changed?

        Rails.logger.info("Funding Frontend Organisation id: " \
          "#{organisation_to_refresh.id} " \
            "was successfully refreshed from #{@salesforce_account_id}.")

        retrieve_page_info
        render :show

      end

    end

  end

  # Saves the org and audits changes
  # Audit row rolled back if org save fails.
  # @param [Organisation] refreshed_org Org instance that has been changed
  #                                                           but not saved
  def save_org_and_audit(refreshed_org)
    Organisation.transaction do # Org save and audit row in a transaction

      create_audit_row(
        current_user,
        refreshed_org,
        Audit.audit_actions['admin_organisation_change'],
        refreshed_org.changes,
      )
      refreshed_org.save!

    rescue ActiveRecord::RecordInvalid => exception
      Rails.logger.error(
        "Update on update_organisation_details_controller failed to save org " \
          "#{refreshed_org.id}. exception: #{exception}"
      )
      raise

    end
  end


  # Gets a salesforce_account_id
  # Uses what FFE has, if there
  # Otherwise grabs from params of submitted form
  #
  # @param [Organisation] organisation_to_refresh User we are refreshing from SF
  # @return [String] salesforce_account_id SF reference for a account
  def get_salesforce_account_id(organisation_to_refresh)

    salesforce_account_id = organisation_to_refresh&.salesforce_account_id

    if salesforce_account_id.blank? # get id from form instead

      salesforce_account_id =
        params.require(
          'no_model'
        ).permit(
          'salesforce_account_id'
          )['salesforce_account_id']

    end

    salesforce_account_id

  end

  # Gets a Organisation details from Salesforce.
  # Handle deleted or invalid Organisation IDs
  #
  # @param [String] salesforce_account_id
  # @return [RestforceResponse] details_in_salesforce
  def get_organisation_from_salesforce(sf_acc_id)

    begin

      details_in_salesforce = 
        retrieve_existing_salesforce_organisation(sf_acc_id)

    rescue  Restforce::ErrorCode::FieldIntegrityException => e
      Rails.logger.error(
        "FieldIntegrityException for salesforce_account_id " \
        "#{@sf_acc_id}: #{e}"
      )
    rescue  => e
      Rails.logger.error(
        "Unknown error for salesforce_account_id " \
        "#{@sf_acc_id}: #{e}"
      )
    end
    
    details_in_salesforce

  end

  # These steps are the same for each validation error scenario
  # So reuse here
  # - logs error
  # - adds err_msg to array to render on form
  #
  # @param [String] log_msg - what Rails logs
  # @param [String] err_msg - what admin user sees upon :show
  def log_error_and_show(log_msg, err_msg)

    Rails.logger.error(log_msg)

    @errors.push(err_msg)

    retrieve_page_info
    render :show

  end

  # Check if the required org fields are present on
  # an organisation returned from a restforce query
  #
  # @param [RestforceResponse] Restforce response containing 
  #             organisation details 
  # @return [Boolean] is org details complete
  def check_org_in_sf_complete?(restforce_details)

    if restforce_details&.BillingStreet.blank? || 
      restforce_details&.BillingCity.blank? ||    
        restforce_details&.BillingPostalCode.blank? || 
          restforce_details&.Name.blank?
            return false
    end

    return true

  end

  # Retrieves an organisation and User by querying their classes using the
  # organisation_id and user_id provided in params.
  # Populates instance variables for @organisation and @user
  # then a further instance variable, @organisation_sf_url, for the SF link
  def retrieve_page_info
    @organisation = Organisation.find(params[:organisation_id])
    @user = User.find(params[:user_id])


    @organisation_sf_url = get_salesforce_organisation_link(
      @organisation&.salesforce_account_id
    )
  end
  

end
