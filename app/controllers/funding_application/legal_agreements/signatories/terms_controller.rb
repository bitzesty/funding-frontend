class FundingApplication::LegalAgreements::Signatories::TermsController < ApplicationController
  include LegalAgreementsContext
  include FundingApplicationHelper

  def show

    set_award_type(@funding_application)

    @award_more_than_10k = @funding_application.open_medium.present?

    @standard_terms_link = get_standard_terms_link(@funding_application)

    @retrieving_a_grant_guidance_link =
      get_receiving_a_grant_guidance_link(@funding_application)

    @receiving_guidance_property_ownership_link =  
      get_receiving_guidance_property_ownership_link(@funding_application)

    @programme_application_guidance =
      get_programme_application_guidance_link(@funding_application)

  end

end
