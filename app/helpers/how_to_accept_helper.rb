module HowToAcceptHelper
  include SalesforceApi


  # Allows use of the saleslforce_api lib file.  
  # Returns owner of the Project in Salesforce - who is should be the
  # Investment manager at this point in the process.
  #
  # Passes through the project id for small, funding application id otherwise
  #
  # @param funding_application [FundingApplication] An instance of a FundingApplication
  # @return String project_owner_name The project owner
  def project_owner_name(funding_application)

    salesforce_api_client = SalesforceApiClient.new

    salesforce_api_client.project_owner_name(funding_application.salesforce_case_id)

  end

end