module FundingApplicationHelper
  include SalesforceApi

  # Method responsible for orchestrating the submission of a funding
  # application to Salesforce
  #
  # @param [FundingApplication] funding_application An instance of a
  #                                                 FundingApplication
  # @param [User] user An instance of a User
  # @param [Organisation] organisation An instance of an Organisation
  def send_funding_application_to_salesforce(
    funding_application,
    user,
    organisation
  )

    salesforce_api_client = SalesforceApiClient.new

    salesforce_references = salesforce_api_client.create_project(
      funding_application,
      user,
      organisation
    )

    funding_application.update(
      submitted_on: DateTime.now,
      salesforce_case_id: salesforce_references[:salesforce_project_reference],
      project_reference_number: salesforce_references[:external_reference],
      salesforce_case_number: salesforce_references[:external_reference].nil? ?
        nil :
        salesforce_references[:external_reference].chars.last(5).join
    )

    user.update(
      salesforce_contact_id: salesforce_references[:salesforce_contact_id]
    ) if user.salesforce_contact_id.nil?

    organisation.update(
      salesforce_account_id: salesforce_references[:salesforce_account_id]
    ) if organisation.salesforce_account_id.nil?

  end

end
