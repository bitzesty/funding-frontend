class AdminPortal::UserFoundController < ApplicationController
  include AdminPortalContext

  def show

    @applicant_found = User.find(params[:user_id])
    @applicant_found_organisation = @applicant_found&.organisations&.first

    @contact_sf_url = get_contact_salesforce_link(
      @applicant_found&.salesforce_contact_id
    )
    
    @organisation_sf_url = get_salesforce_organisation_link(
      @applicant_found_organisation&.salesforce_account_id
    )

  end

end
