class AdminPortal::ApplicationToMoveController < ApplicationController
  include AdminPortalContext
  include AdminPortalHelper

  def show

    initialise_page_for_show

  end

  def update

    application_id =
      params.fetch(:no_model, {}).permit(:selected_project)[:selected_project]

    if application_id.present?

      redirect_to(
        admin_portal_new_main_contact_path(
        user_id: params[:user_id],
        organisation_id: params[:organisation_id],
        application_id: application_id
        )
      )

    else
      initialise_page_for_show
      @nothing_selected = true
      render :show

    end
  end

  # initialises page for showing to user
  def initialise_page_for_show

    @nothing_selected = false

    @current_main_contact = User.find(params['user_id'])

    @current_main_contact_organisation =
      Organisation.find(params['organisation_id'])

    @main_contact_apps = get_main_contact_apps(
      params['organisation_id'],
      params['user_id']
    )
  end

end
