module DashboardHelper
  include SalesforceApi


  # Allows use of the saleslforce_api lib file.  
  # Returns true if the project is awarded
  # Only makes the Salesforce call if the application has a status of submitted.
  # Passes through the project id for small, funding application id otherwise
  # The salesforce_api_client is passed in to reduce instances.
  # TODO - Do not call Salesforce if we have made all payments for an application.

  # @param funding_application [FundingApplication] An instance of a FundingApplication
  # @param salesforce_api_client [SalesforceApiClient] An instance of a SalesforceApiClient
  # @return Boolean True if the project is awarded otherwise false
  def awarded(funding_application, salesforce_api_client)
    
    if funding_application.submitted_on.present?

      salesforce_external_id = 
        funding_application.project.present? ? funding_application.project.id : funding_application.id 

      awarded = salesforce_api_client.is_project_awarded(salesforce_external_id)

    else

      awarded = false  

    end

    awarded

  end

  # Creates and returns an instance of SalesforceApiClient
  # @return SalesforceApiClient [SalesforceApiClient] an instance of this class
  def get_salesforce_api_instance()
    salesforce_api_client= SalesforceApiClient.new
  end 

end