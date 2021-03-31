# Stub controller
class FundingApplication::GpOpenMedium::HeritageFormalDesignationDescriptionController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def update
    redirect_to :funding_application_gp_open_medium_visitors    
  end

end
