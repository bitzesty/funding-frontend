class FundingApplication::LegalAgreements::Signatories::CheckDetailsController < ApplicationController
  include LegalAgreementsContext
  include ObjectErrorsLogger
  include CheckDetailsHelper
  include FundingApplicationHelper

  def show
    
    content = salesforce_content_for_form(@funding_application)

    # @project_details is a Restforce object containing query results 
    @project_details = content[:project_details]

    # @project_costs is a Restforce object containing costs
    @project_costs = content[:project_costs]

    # @cash_contributions is a Restforce object containing costs
    @cash_contributions = content[:cash_contributions]

    # @project_approved_purposes is a Restforce object containing costs
    @project_approved_purposes = content[:project_approved_purposes]
    
    # upon show, only cerain content is shown for 10-250k applications.
    @award_more_than_10k = @funding_application.open_medium.present?

    # get the relevant links for the award type
    @standard_terms_link = get_standard_terms_link(@funding_application)

    @retrieving_a_grant_guidance_link =
      get_receiving_a_grant_guidance_link(@funding_application)

  end

  helper_method :get_translation

end
