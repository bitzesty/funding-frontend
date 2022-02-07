class FundingApplication::LegalAgreements::Signatories::AgreeController < ApplicationController
  include LegalAgreementsContext

  def show

  end

  def update

    redirect_to(:funding_application_signatories_upload_terms_and_conditions)

  end

end
