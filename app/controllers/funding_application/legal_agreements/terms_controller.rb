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

    # This was duplicated from sign terms controller during a bug fix.  
    # Given time, would be good to write a helper function to consolidate the
    # filenames in one place.  Maybe cater for the signatory download links 
    # too.
    @download_link = 
      '/terms_and_conditions/Applicant only National Lottery Heritage Fund terms and ' \
        'conditions for £3,000 to £10,000.docx' \
          if @funding_application.is_3_to_10k?

    @download_link = 
      '/terms_and_conditions/Applicant only National Lottery Heritage ' \
        'Fund terms and conditions for £10,000 to £100,000.docx' \
          if @funding_application.is_10_to_100k?

    @download_link = 
      '/terms_and_conditions/Applicant only National Lottery Heritage ' \
        'Fund terms and conditions for £100,000 to £250,000.docx' \
          if @funding_application.is_100_to_250k?       
    
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
