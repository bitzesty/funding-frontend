module CheckDetailsHelper
  include SalesforceApi


  # Allows use of the saleslforce_api lib file.  
  # Returns owner of the Project in Salesforce - who is should be the
  # Investment manager at this point in the process.
  #
  # Passes through the project id for small, funding application id otherwise
  #
  # @param funding_application [FundingApplication] An instance of a FundingApplication
  # @return String project_owner_name The project owner
  def salesforce_content_for_form(funding_application)

    salesforce_api_client = SalesforceApiClient.new

    project_details = 
      salesforce_api_client.project_details \
        (funding_application.salesforce_case_id)

    project_costs = 
      salesforce_api_client.project_costs \
        (funding_application.salesforce_case_id)

    project_approved_purposes = 
      salesforce_api_client.project_approved_purposes \
        (funding_application.salesforce_case_id)

    cash_contributions = 
      salesforce_api_client.cash_contributions \
        (funding_application.salesforce_case_id)

    { "project_details": project_details, "project_costs": project_costs, \
      "project_approved_purposes": project_approved_purposes, \
        "cash_contributions": cash_contributions}

  end

end