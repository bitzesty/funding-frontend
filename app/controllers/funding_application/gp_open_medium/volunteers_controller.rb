# Stub controller
class FundingApplication::GpOpenMedium::VolunteersController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def update
    redirect_to :funding_application_gp_open_medium_evidence_of_support
  end

end
