# Stub controller
class FundingApplication::GpOpenMedium::CapitalWorksController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def update
    redirect_to :funding_application_gp_open_medium_acquisition
  end

end
