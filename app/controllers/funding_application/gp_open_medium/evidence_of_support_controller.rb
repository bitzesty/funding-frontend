# Stub controller
class FundingApplication::GpOpenMedium::EvidenceOfSupportController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def update
    redirect_to :funding_application_gp_open_medium_governing_documents    
  end

end
