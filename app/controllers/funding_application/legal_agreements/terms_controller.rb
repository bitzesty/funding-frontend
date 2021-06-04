class FundingApplication::LegalAgreements::TermsController < ApplicationController
  include FundingApplicationContext
  include FundingApplicationHelper
  include ObjectErrorsLogger

  def show

    @applicant_is_legal_signatory = is_applicant_legal_signatory?(
      @funding_application,
      current_user
    )
  
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
