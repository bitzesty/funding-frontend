# Controller for a page that asks whether heritage is at risk
class FundingApplication::GpOpenMedium::CheckAnswersController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger
  
  # Stubbed method
  def update

    redirect_to :funding_application_gp_open_medium_confirm_declaration

  end

end
