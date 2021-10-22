class SalesforceExperienceApplication::StatutoryPermissionOrLicence::ChangeController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  # Loads the attr_accessor variables from the stored json into the object
  def show

    @statutory_permission_or_licence = 
      @salesforce_experience_application.statutory_permission_or_licence.\
        find(params[:statutory_permission_or_licence_id])

    licence_date = 
      Date.parse(@statutory_permission_or_licence.details_json[:date.to_s])

    @statutory_permission_or_licence.date_day = licence_date.day
    @statutory_permission_or_licence.date_month = licence_date.month
    @statutory_permission_or_licence.date_year = licence_date.year

    @statutory_permission_or_licence.licence_type = 
      @statutory_permission_or_licence.details_json[:licence_type.to_s]

  end

  def update

    @statutory_permission_or_licence = 
      @salesforce_experience_application.statutory_permission_or_licence.\
        find(params[:statutory_permission_or_licence_id])

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
