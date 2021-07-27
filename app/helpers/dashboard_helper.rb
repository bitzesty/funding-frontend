module DashboardHelper
  include SalesforceApi
  include FundingApplicationHelper

  # Allows use of the saleslforce_api lib file.  
  # Returns true if a legal agreement is in place
  # The salesforce_api_client is passed in to reduce instances.
  #
  # Todo: At the moment this function will never allowed awards over
  # 100k to begin the payment journey.  This is so that the design can
  # be finished.
  #
  # When payments > 100k can be enabled.  Remove reference to 
  # FundingApplicationHelper and remove the lines indicated by comments below.

  # @param funding_application [FundingApplication] An instance of a 
  #                                                        FundingApplication
  # @param salesforce_api_client [SalesforceApiClient] An instance of 
  #                                                        a SalesforceApiClient
  # @return Boolean True if the project is awarded otherwise false
  def legal_agreement_in_place?(funding_application, salesforce_api_client)
  
    # remove once payments > 100k allowed
    set_award_type(funding_application)

    # Remove "&& !funding_application.is_100_to_250k?" when payments 
    # over 100k allowed 
    if funding_application.submitted_on.present? && 
        !funding_application.is_100_to_250k?

      salesforce_external_id = 
        funding_application.project.present? ? funding_application.project.id : funding_application.id 

        legal_agreement_in_place = salesforce_api_client.legal_agreement_in_place?(salesforce_external_id)

    else

      legal_agreement_in_place = false  

    end

    legal_agreement_in_place

  end

  # Creates and returns an instance of SalesforceApiClient
  # @return SalesforceApiClient [SalesforceApiClient] an instance of this class
  def get_salesforce_api_instance()
    salesforce_api_client= SalesforceApiClient.new
  end 

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

end