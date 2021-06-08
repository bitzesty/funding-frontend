# Controller concern used to set the @funding_application
# instance variable and to determine whether a legal
# signatory should have access
module LegalAgreementsContext
  extend ActiveSupport::Concern
  include LegalAgreementsHelper
  included do
    before_action :set_funding_application
  end

  # This method retrieves a FundingApplication object based on the GUID
  # found in the URL parameters and the current authenticated
  # user's id, setting it as an instance variable for use in
  # funding application-related controllers.
  #
  # If no FundingApplication object matching the parameters is found,
  # then the user is redirected to the applications dashboard.
  def set_funding_application

    redirect_to :root if not_an_allowed_path?(request.path)

    @funding_application = FundingApplication.find_by(
      id: params[:application_id],
    )

    redirect_to :root unless @funding_application&.submitted_on.present? \
      && encoded_signatory_id_verifies?(
        @funding_application,
        params[:encoded_signatory_id]
      )

  end

  private

  def not_an_allowed_path?(path)

    path.exclude?('check-project-details') &&
      path.exclude?('terms-and-conditions') &&
      path.exclude?('sign-terms-and-conditions') &&
      path.exclude?('submitted')
    
  end
  
end
  