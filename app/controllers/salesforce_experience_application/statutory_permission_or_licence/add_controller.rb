class SalesforceExperienceApplication::StatutoryPermissionOrLicence::AddController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  # In memory object form use by form.
  def show
    @statutory_permission_or_licence = 
      @salesforce_experience_application.statutory_permission_or_licence.new
  end

  # In memory object form use by form. Saved if validation OK.
  def update

    @statutory_permission_or_licence = 
      @salesforce_experience_application.statutory_permission_or_licence.new

    update_statutory_permission_or_licence
  
  end

  private

  def permitted_params

    params.fetch(
      :statutory_permission_or_licence, {}).permit(
        :licence_type, :date_day, :date_month, :date_year
      ) 

  end
  
end
