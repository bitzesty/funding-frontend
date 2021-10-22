class SalesforceExperienceApplication::PermissionsOrLicencesController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show
    initialize_view()
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
            sfx_pts_payment_statutory_permission_or_licence_add_path \
              (@salesforce_experience_application.salesforce_case_id)
          )
      else
        redirect_to(
          sfx_pts_payment_signatories_path \
            (@salesforce_experience_application.salesforce_case_id)
        )
      end
    
    else
       
      render :show

    end

  end

  private

  def initialize_view() 
    if @salesforce_experience_application
      .pts_answers_json["permissions_or_licences_received"] == true.to_s
      @salesforce_experience_application.permissions_or_licences_received = true.to_s
    elsif @salesforce_experience_application
      .pts_answers_json["permissions_or_licences_received"] == false.to_s
      @salesforce_experience_application.permissions_or_licences_received = false.to_s
    end
  end
  
end
