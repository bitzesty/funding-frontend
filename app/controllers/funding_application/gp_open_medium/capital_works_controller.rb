# Stub controller
class FundingApplication::GpOpenMedium::CapitalWorksController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def update
    redirect_to :funding_application_gp_open_medium_do_you_need_permission
  end

end
