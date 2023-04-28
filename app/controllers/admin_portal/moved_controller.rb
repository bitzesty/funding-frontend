class AdminPortal::MovedController < ApplicationController
  include AdminPortalContext
  include AdminPortalHelper

  def show

    initialise_controller

  end

  # initialises page for showing to user
  def initialise_controller

    @updated_main_contact = User.find(params['new_main_contact_id'])

    main_contact_apps = get_main_contact_apps(
      @updated_main_contact.organisations.first.id,
      @updated_main_contact.id
    )

    @chosen_app_hash = get_chosen_app_hash(
      main_contact_apps,
      params['application_id']
    )

  end

end
