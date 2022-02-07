class FundingApplication::LegalAgreements::ProjectDetailsCorrectController < ApplicationController
  include FundingApplicationContext
  include FundingApplicationHelper

  def show

  end

  def update

    @funding_application.validate_details_correct = true

    @funding_application.details_correct =
      params[:funding_application].nil? ? nil : 
        params[:funding_application][:details_correct]

    if @funding_application.valid?
      # The agreements journey changed from its original form and an applicant
      # Doesn't explicitly "agree" anymore.
      # However, this audits that they passed the project-details-correct view.
      @funding_application.agreement.update(grant_agreed_at: DateTime.now)

      logger.info "grant_agreed_at timestamp set for " \
        "funding_application ID: #{@funding_application.id} as " \
          "applicant has submitted agreements details."
      
      redirect_to :funding_application_applicant_is_signatory

    else
      render :show
    end

  end

end
