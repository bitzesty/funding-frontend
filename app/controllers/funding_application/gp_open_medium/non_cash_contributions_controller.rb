# Stub controller
class FundingApplication::GpOpenMedium::NonCashContributionsController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def update
    redirect_to :funding_application_gp_open_medium_volunteers    
  end

end
