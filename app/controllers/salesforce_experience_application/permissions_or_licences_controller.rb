class SalesforceExperienceApplication::PermissionsOrLicencesController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show

  end

  def update 
    
    @salesforce_experience_application.validate_permissions_or_licences_received = true
    
    @salesforce_experience_application.permissions_or_licences_received = 
      params[:sfx_pts_payment].nil? ? nil : params[:sfx_pts_payment][:permissions_or_licences_received]
    
    if @salesforce_experience_application.valid?
      
      json_answers = @salesforce_experience_application.pts_answers_json

      json_answers[:permissions_or_licences_received] = 
        @salesforce_experience_application.permissions_or_licences_received

      @salesforce_experience_application.pts_answers_json = json_answers
      @salesforce_experience_application.save

      if @salesforce_experience_application. \
        permissions_or_licences_received.downcase == "true"
          redirect_to(
            sfx_pts_payment_add_permissions_or_licences_path \
              (@salesforce_experience_application.salesforce_case_id)
          )
      else
        redirect_to(
          sfx_pts_payment_declaration_path \
            (@salesforce_experience_application.salesforce_case_id)
        )
      end
    
    else
       
      render :show

    end

  end
  
end
