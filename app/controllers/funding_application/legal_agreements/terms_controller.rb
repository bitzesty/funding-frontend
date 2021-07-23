class FundingApplication::LegalAgreements::TermsController < ApplicationController
  include FundingApplicationContext
  include FundingApplicationHelper
  include ObjectErrorsLogger
  include LegalAgreementsHelper

  def show

    @applicant_is_legal_signatory = is_applicant_legal_signatory?(
      @funding_application,
      current_user
    )

    set_award_type(@funding_application)

    @award_more_than_10k = @funding_application.open_medium.present?

    @standard_terms_link = get_standard_terms_link(@funding_application)

    @retrieving_a_grant_guidance_link =
      get_receiving_a_grant_guidance_link(@funding_application)

    @receiving_guidance_property_ownership_link =  
      get_receiving_guidance_property_ownership_link(@funding_application)

    @programme_application_guidance =
      get_programme_application_guidance_link(@funding_application)
    
    @additional_grant_conditions = additional_grant_conditions(@funding_application)

    @investment_manager_name = project_details(@funding_application).Owner.Name
    
  end

  def update

    logger.info(
      'Updating terms_agreed_at attribute for funding_application ID: ' \
      "#{@funding_application.id}"
    )

    @funding_application.agreement.update(
      terms_agreed_at: DateTime.now
    )

    logger.info(
      'Finished Updating terms_agreed_at attribute for ' \
      "funding_application ID: #{@funding_application.id}"
    )

    redirect_to(:funding_application_agreed)

  end

end
