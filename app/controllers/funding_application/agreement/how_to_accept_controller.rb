class FundingApplication::Agreement::HowToAcceptController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # Method used to render the 'show' view with dynamic content
  # specific to the relevant FundingApplication
  def show

    # TODO: Retrieve Investment Manager name from Salesforce
    @investment_manager_name = "Stuart McColl"

    render :show

  end

end
