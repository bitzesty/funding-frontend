class FundingApplication::LegalAgreements::AgreeController < ApplicationController
  include FundingApplicationContext

  def show

  end

  def update

    redirect_to(:funding_application_upload_terms_and_conditions)

  end

end
