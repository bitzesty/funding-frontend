module ProgressAndSpendHelper
  include SalesforceApi

  # Method responsible for orchestrating the retrieval of
  # additional grant conditions from Salesforce
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  def salesforce_additional_grant_conditions(funding_application)

    client = SalesforceApiClient.new

    case_id = funding_application.salesforce_case_id

    additional_grant_conditions =
      client.additional_grant_conditions \
        (funding_application.salesforce_case_id)

  end
  
end
