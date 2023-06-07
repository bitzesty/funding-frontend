class AdminPortal::UpdateContactDetailsController < ApplicationController
  include AdminPortalContext
  include ImportHelper
  include UserHelper
  include DashboardHelper
  include Auditor

  NOT_FOUND_ERR = 'Salesforce Contact Id not found'

  INCOMPLETE_ERR = "Contact details are incomplete in Salesforce. " \
    "Check Last Name, Mailing Street, " \
      "Mailing City and Mailing Zip/Postal Code"

  def show
    retrieve_user
  end

  def update
    update_contact_details
    retrieve_user
    render :show
  end

  # Show method for move all projects
  def move_all_show
    retrieve_user
    retrieve_apps
    render('admin_portal/move_all_projects/show')
  end

  # update method for move all projects
  def move_all_update
    update_contact_details
    retrieve_user
    retrieve_apps
    render('admin_portal/move_all_projects/show')
  end

  # @param [case_id] String Salesforce reference for a Project record
  # @return [get_project_title_with_sf_connection] String A project title
  def get_project_title(case_id)
    @salesforce_api_instance = get_salesforce_api_instance()
    get_project_title_with_sf_connection(@salesforce_api_instance, case_id)
  end
  helper_method :get_project_title

  private

  def retrieve_apps
    @apps_to_move = @user_details.organisations.first.funding_applications
    @preapps_to_move = @user_details.organisations.first.pre_applications
  end

  # Gets a Contact details from Salesforce.
  # Handle deleted or invalid contact IDs
  #
  # @param [String] salesforce_contact_id
  # @return [RestforceResponse] contact_from_salesforce
  def get_contact_from_salesforce(salesforce_contact_id)

    begin
      contact_from_salesforce =
        retrieve_existing_salesforce_contact(@salesforce_contact_id)
    rescue Restforce::ErrorCode::FieldIntegrityException => e
      Rails.logger.error(
        "FieldIntegrityException for salesforce_contact_id " \
        "#{@salesforce_contact_id}: #{e}"
      )
    rescue => e
      Rails.logger.error(
        "Unknown error for salesforce_contact_id " \
        "#{@salesforce_contact_id}: #{e}"
      )
    end

    contact_from_salesforce

  end

  # Gets a salesforce_contact_id
  # Uses what FFE has, if there
  # Otherwise grabs from params of submitted form
  #
  # @param [User] user_to_refresh User we are refreshing from SF
  # @return [String] salesforce_contact_id SF reference for a contact
  def get_salesforce_contact_id(user_to_refresh)

    salesforce_contact_id = user_to_refresh&.salesforce_contact_id

    if salesforce_contact_id.blank? # get id from form instead

      salesforce_contact_id =
        params.require(
          'no_model'
        ).permit(
          'salesforce_contact_id'
          )['salesforce_contact_id']

    end

    salesforce_contact_id

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

  end

  def retrieve_user
    @user_details = User.find(params[:user_id])

    @contact_sf_url = get_contact_salesforce_link(
      @user_details&.salesforce_contact_id
    )
  end

  def update_contact_details
    @errors = []

    user_to_refresh = User.find(params[:user_id])

    @salesforce_contact_id = get_salesforce_contact_id(user_to_refresh)

    contact_from_salesforce =
      get_contact_from_salesforce(@salesforce_contact_id)

    if contact_from_salesforce.blank?

      not_found_log = "Funding Frontend User id: #{user_to_refresh.id} " \
        "COULD NOT refresh from Salesforce. Contact Id: " \
          "#{@salesforce_contact_id} not found."

      log_error_and_show(not_found_log, NOT_FOUND_ERR)

    else

      unless salesforce_contact_complete?(contact_from_salesforce)

        incomplete_log = "Funding Frontend User id: #{user_to_refresh.id} " \
          "COULD NOT refresh from Salesforce. Contact Id: " \
            "#{@salesforce_contact_id} is incomplete."

        log_error_and_show(incomplete_log, INCOMPLETE_ERR)

      else

        begin

          Rails.logger.info("Funding Frontend User id: " \
            "#{user_to_refresh.id} " \
              "being refreshed from #{@salesforce_contact_id}.")

          populate_user_from_restforce_object(
            user_to_refresh,
            contact_from_salesforce,
            skip_email_change_notification = true,
            audit_changes = true
          )

          replicate_user_attributes_to_associated_person(user_to_refresh)
          check_and_set_person_address(user_to_refresh)

          Rails.logger.info("Funding Frontend User id: #{user_to_refresh.id} " \
            "was successfully refreshed from #{@salesforce_contact_id}.")

        rescue ActiveRecord::RecordInvalid => e

          duplicate_email_err =
            "Contact details could not be updated, Funding Frontend " \
              " may already have a user with the email " \
                "#{contact_from_salesforce.Email}"

          log_error_and_show(e, duplicate_email_err)

        end

      end

    end
  end

end
