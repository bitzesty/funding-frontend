class SalesforceExperienceApplication::DeclarationController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show
    initialize_view()
  end

  def update

    @salesforce_experience_application.validate_agrees_to_declaration = true
    
    @salesforce_experience_application.agrees_to_declaration = 
      params[:sfx_pts_payment].nil? ? nil : 
        params[:sfx_pts_payment][:agrees_to_declaration] == 'true'
    
    if @salesforce_experience_application.valid?
      
      json_answers = @salesforce_experience_application.pts_answers_json

      json_answers[:agrees_to_declaration] = 
        @salesforce_experience_application.agrees_to_declaration

      @salesforce_experience_application.pts_answers_json = json_answers
      @salesforce_experience_application.save

      redirect_to(
        sfx_pts_payment_download_instructions_path \
          (@salesforce_experience_application.salesforce_case_id)
      )

    else
       
      render :show

    end

  end

  private

  def initialize_view() 
    if @salesforce_experience_application
      .pts_answers_json["agrees_to_declaration"] == true
      @salesforce_experience_application.agrees_to_declaration = true
    elsif @salesforce_experience_application
      .pts_answers_json["agrees_to_declaration"] == false
      @salesforce_experience_application.agrees_to_declaration = false
    end
  end
  
end
