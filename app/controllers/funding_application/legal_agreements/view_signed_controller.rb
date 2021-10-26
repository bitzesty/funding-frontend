class FundingApplication::LegalAgreements::ViewSignedController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def show

    @stored_details = @funding_application.agreement&.project_details_html
    @stored_terms = @funding_application.agreement&.terms_html

    @terms_agreed_at = 
      @funding_application.agreement&.terms_agreed_at.strftime("%d/%m/%y") \
        unless @funding_application.agreement&.terms_agreed_at.nil?

  end

end
