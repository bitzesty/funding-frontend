class SalesforceExperienceApplication::SignatoriesController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show
    
  end

  def update 

    @salesforce_experience_application.validate_legal_sig_one = true
    @salesforce_experience_application.validate_legal_sig_two= true

    @salesforce_experience_application.legal_sig_one =
      params[:sfx_pts_payment][:legal_sig_one]

    @salesforce_experience_application.legal_sig_two =
      params[:sfx_pts_payment][:legal_sig_two]

    if @salesforce_experience_application.valid?
      
      json_answers = @salesforce_experience_application.pts_answers_json

      json_answers[:legal_sig_one] = 
      @salesforce_experience_application.legal_sig_one

      json_answers[:legal_sig_two] = 
      @salesforce_experience_application.legal_sig_two

      @salesforce_experience_application.pts_answers_json = json_answers

      @salesforce_experience_application.save

      redirect_to(
        sfx_pts_payment_partnerships_path \
          (@salesforce_experience_application.salesforce_case_id)
      )

    else
      render :show
    end

  end
  
end
