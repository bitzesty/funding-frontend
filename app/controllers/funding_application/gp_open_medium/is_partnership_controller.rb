# Stub controller
class FundingApplication::GpOpenMedium::IsPartnershipController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def update
    redirect_to :funding_application_gp_open_medium_how_will_your_project_involve_people    
  end

end
