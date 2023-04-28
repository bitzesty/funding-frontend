class AdminPortal::NewMainContactController < ApplicationController
  include AdminPortalContext
  include AdminPortalHelper
  include UserHelper
  include OrganisationHelper

  DOES_NOT_EXIST = "Contact with this email does not exist in Funding Frontend"
  CONTACT_INCOMPLETE =
    "Contact with this email isn't complete in Funding Frontend"
  ORGANISATION_INCOMPLETE =
    "Organisation for contact with this email isn't complete in Funding " \
      "Frontend"
  NOT_IN_SALESFORCE =
    "The application is in Salesforce. Both the new main contact and their " \
      "organisation must be in Salesforce"

  def show
    initialise_controller
  end

  def update

    initialise_controller

    email = params.require(:no_model).permit(:email)[:email]

    new_main_contact = User.find_by(email: email.downcase.strip)
    new_org = new_main_contact&.organisations&.first

    if new_main_contact_suitable?(new_main_contact, new_org, @chosen_app_hash)

      redirect_to(
        admin_portal_move_application_path(
          user_id: params[:user_id],
          organisation_id: params[:organisation_id],
          application_id: params[:application_id],
          new_main_contact_id: new_main_contact.id,
          new_org_id: new_org.id
        )
      )

    else

      initialise_controller
      @entered_email = email
      render :show

    end

  end

  # initialises page for showing to user
  def initialise_controller

    @current_main_contact = User.find(params['user_id'])

    @current_main_contact_organisation =
      Organisation.find(params['organisation_id'])

    @main_contact_apps = get_main_contact_apps(
      params['organisation_id'],
      params['user_id']
    )

    @chosen_app_hash = get_chosen_app_hash(
      @main_contact_apps,
      params['application_id']
    )

  end

  # Checks for suitability:
  # - new contact exists in FFE
  # - new contact is a complete contact in FFE
  # - new contact has a complete org
  # - if application in SF, then new contact and their org must be too.
  #
  # @param [User] new_main_contact User instance for new main contact
  # @param [Organisation] new_org Organisation instance for new main contact
  # @param [Hash] chosen_app Hash, example:
  #         {:id=>"", :ref_no=>"", :type=>1, :title=>"", salesforce_id => ""}
  # @return [Boolean] True unless checks fail
  #
  def new_main_contact_suitable?(new_main_contact, new_org, chosen_app_hash)

    # new contact exists in FFE
    if new_main_contact.nil?
      @error_message = DOES_NOT_EXIST
      return false
    end

    # new contact is a complete contact in FFE
    unless user_details_complete(new_main_contact)
      @error_message = CONTACT_INCOMPLETE
      return false
    end

    # new contact has a complete org
    unless complete_organisation_details?(new_org) && \
      complete_organisation_details_for_pre_application?(new_org)

      @error_message = ORGANISATION_INCOMPLETE
      return false
    end

    # if application in SF, then new contact and their org must be too.
    if chosen_app_hash[:salesforce_id].present?

      if new_main_contact.salesforce_contact_id.nil? ||
        new_org.salesforce_account_id.nil?

        @error_message = NOT_IN_SALESFORCE
        return false
      end
    end

    # checks pass
    true

  end

end
