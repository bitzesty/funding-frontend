class FundingApplication::LegalAgreements::CheckDetailsController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger
  include CheckDetailsHelper

  def show
    
    content = salesforce_content_for_form(@funding_application)

    # @project_details is a Restforce object containing query results 
    @project_details = content[:project_details]

    # @project_costs is a Restforce object containing costs
    @project_costs = content[:project_costs]

    # @project_approved_purposes is a Restforce object containing costs
    @project_approved_purposes = content[:project_approved_purposes]

  end

end
