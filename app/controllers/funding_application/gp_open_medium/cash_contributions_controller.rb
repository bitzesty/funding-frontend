# Stub controller
class FundingApplication::GpOpenMedium::CashContributionsController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def update
    redirect_to :funding_application_gp_open_medium_are_you_getting_non_cash_contributions    
  end

end
