class SalesforceExperienceApplication::ApprovedPurposesController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show
    initialize_view() 
    set_approved_purposes()
  end

  def update 

    @salesforce_experience_application.validate_approved_purposes_match = true
    
    @salesforce_experience_application.approved_purposes_match = 
      params[:sfx_pts_payment].nil? ? nil : 
        params[:sfx_pts_payment][:approved_purposes_match]
    
    if @salesforce_experience_application.valid?
      
      json_answers = @salesforce_experience_application.pts_answers_json

      json_answers[:approved_purposes_match] = 
        @salesforce_experience_application.approved_purposes_match

      @salesforce_experience_application.pts_answers_json = json_answers
      @salesforce_experience_application.save

      redirect_to(
        sfx_pts_payment_agreed_costs_path(
          @salesforce_experience_application.salesforce_case_id
        )
      )
    
    else

      set_approved_purposes()
       
      render :show

    end

  end

  private 

  def set_approved_purposes()
    @approved_purposes = get_approved_purposes(
      @salesforce_experience_application.salesforce_case_id
    )
  end

  def initialize_view() 
    if @salesforce_experience_application
      .pts_answers_json["approved_purposes_match"] == true.to_s
      @salesforce_experience_application.approved_purposes_match = true.to_s
    elsif @salesforce_experience_application
      .pts_answers_json["approved_purposes_match"] == false.to_s
      @salesforce_experience_application.approved_purposes_match = false.to_s
    end
  end

end
