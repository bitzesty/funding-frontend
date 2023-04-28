# Controller concern used to check auth and admin used for Admin portal pages
module AdminPortalContext
	extend ActiveSupport::Concern
	included do
		before_action :authenticate_user!, :ensure_user_is_admin
	end

  # This method retrieves a SfxPtsPayment instance based on the id
  # found in the URL parameters and the current authenticated
  # user's id, setting it as an instance variable for use in
  # related controllers.
  #
  # If no SfxPtsPayment instance matching the parameters is found,
  # or the SfxPtsPayment instance is not suitable for the route being used,
  # then the user is redirected to the applications dashboard.
  def ensure_user_is_admin

    unless current_user.admin?

        logger.error("Non-admin user attempting to access " \
          "admin portal, redirected to root")

        redirect_to :authenticated_root

    end

  end

  # Returns a link that can be used to find the Contact in Salesforce
  # @return [String] url Link to the contact in SF
  def get_contact_salesforce_link(salesforce_contact_id)

    return "#{SALESFORCE_URL_BASE}/lightning"\
      "/r/Contact/"\
        "#{salesforce_contact_id}"\
          "/view"
  end

  # Returns a link that can be used to find the Account in Salesforce
  # @return [String] url Link to the Account in SF
  def get_salesforce_organisation_link(
    salesforce_account_id
  )
    return "#{SALESFORCE_URL_BASE}/lightning"\
      "/r/Account/"\
        "#{salesforce_account_id}"\
          "/view"
  end

end
