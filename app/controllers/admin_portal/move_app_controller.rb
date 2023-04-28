class AdminPortal::MoveAppController < ApplicationController
  include AdminPortalContext
  include AdminPortalHelper

  def show

    initialise_controller

  end

  def update

    initialise_controller

    move_app_to_new_user(
      @chosen_app_hash,
      @new_main_contact.id,
      @new_main_contact_organisation.id
    )

    redirect_to(
      admin_portal_moved_path(
      user_id: @new_main_contact.id,
      organisation_id: @new_main_contact_organisation.id,
      application_id: params['application_id']
      )
    )
  end

  # initialises page for showing to user
  def initialise_controller

    @current_main_contact = User.find(params['user_id'])

    @current_main_contact_organisation =
      Organisation.find(params['organisation_id'])

    @new_main_contact = User.find(params['new_main_contact_id'])

    @new_main_contact_organisation =
      Organisation.find(params['new_org_id'])

    @main_contact_apps = get_main_contact_apps(
      params['organisation_id'],
      params['user_id']
    )

    @chosen_app_hash = get_chosen_app_hash(
      @main_contact_apps,
      params['application_id']
    )

  end

end
