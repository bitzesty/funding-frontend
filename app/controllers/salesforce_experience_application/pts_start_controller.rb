class SalesforceExperienceApplication::PtsStartController < ApplicationController
  include PermissionToStartHelper

  def show
    @salesforce_info_for_page = 
      get_info_for_start_page(params.fetch(:salesforce_case_id))
  end

  def update

    salesforce_case_id = params.fetch(:salesforce_case_id)

    salesforce_case = SfxPtsPayment.find_or_create_by(salesforce_case_id:
       salesforce_case_id)
    
    if salesforce_case.email_address.blank?
      salesforce_case.email_address = current_user.email
      salesforce_case.save
    end

    redirect_to(
      sfx_pts_payment_approved_purposes_path(salesforce_case_id)
    )

  end
    
end
