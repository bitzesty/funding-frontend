class SalesforceExperienceApplication::AgreedCostsController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show
    set_agreed_costs()
  end

  def update 
    
    @salesforce_experience_application.validate_agreed_costs_match = true
    
    @salesforce_experience_application.agreed_costs_match = 
      params[:costs_are_correct]

     if @salesforce_experience_application.valid?

      json_answers = @salesforce_experience_application.pts_answers_json

      json_answers[:agreed_costs_match] = 
        @salesforce_experience_application.agreed_costs_match

      @salesforce_experience_application.pts_answers_json = json_answers
      @salesforce_experience_application.save

      redirect_to(
        sfx_pts_payment_agreed_costs_documents_path \
          (@salesforce_experience_application.salesforce_case_id)
      )

     else 
      set_agreed_costs()
      render :show
     end
  end

  private

  def set_agreed_costs()
    @agreed_costs =  get_agreed_costs(@salesforce_experience_application)
    @total_contingency = get_total_contingency(@agreed_costs)
  end
  
end
