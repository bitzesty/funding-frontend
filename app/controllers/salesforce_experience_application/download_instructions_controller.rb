class SalesforceExperienceApplication::DownloadInstructionsController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show
    
  end

  def update
    redirect_to(
      sfx_pts_payment_print_form_path \
        (@salesforce_experience_application.salesforce_case_id)
    )
  end
end 