class SalesforceExperienceApplication::PartnershipsController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show
    initialize_view()
  end

  def update

    if validate_and_store_answers(params)
      redirect_to(
        sfx_pts_payment_declaration_path(
          @salesforce_experience_application.salesforce_case_id
        )
      )
      
    else
      render :show
    end

  end

  private 

  def validate_and_store_answers(params)

    result = false

    logger.info(
      'Save and continue clicked on apply on behalf of' \
        'partnership for case ID:' \
          "#{@salesforce_experience_application.salesforce_case_id}"
    )

    @salesforce_experience_application.validate_partnership_application = true

    @salesforce_experience_application.partnership_application = 
      params[:sfx_pts_payment].nil? ? nil : \
        params[:sfx_pts_payment][:partnership_application]

    @salesforce_experience_application.project_partner_name  = 
      params[:sfx_pts_payment].nil? ? nil : \
        params[:sfx_pts_payment][:project_partner_name]     

    @salesforce_experience_application.validate_project_partner_name = true if 
      @salesforce_experience_application.partnership_application == "true"

    if @salesforce_experience_application.valid?
        update_pts_answers_json(
          :partnership_application,
          @salesforce_experience_application.partnership_application
        )

        update_pts_answers_json(
          :project_partner_name,
          @salesforce_experience_application.project_partner_name 
        )

        result = true
    end

    clear_pts_answers_json_for_key(:project_partner_name) if 
    @salesforce_experience_application.partnership_application == "false"

    return result
  end

  private
  
  def initialize_view() 
    if @salesforce_experience_application
      .pts_answers_json["partnership_application"] == true.to_s
        @salesforce_experience_application.partnership_application = true.to_s
        @salesforce_experience_application
          .project_partner_name = @salesforce_experience_application
            .pts_answers_json["project_partner_name"]
    elsif @salesforce_experience_application
      .pts_answers_json["partnership_application"] == false.to_s
        @salesforce_experience_application.partnership_application = false.to_s
    end
  end

end
