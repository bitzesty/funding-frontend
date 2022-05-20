module PaymentRequestSalesforceApi

  # Class to allow interaction with Salesforce via a Restforce client
  class PaymentRequestSalesforceApiClient
    include SalesforceApiHelper

    # Overrides the .new() method, allowing us to initialise a Restforce client
    # when the class is instantiated
    def initialize

      initialise_client

    end

    # Method to get an aggregated list of cost headings from salesforce.
    #
    # @param [string] case_id Salesforce reference for a case
    # @param [string] record_type_id Salesforce id for a project cost
    #                                 record type.
    # @return [Array] result_array.  Array of cost headings
    def salesforce_cost_headings(case_id, record_type_id)

      Rails.logger.info("Retrieving salesforce cost headings" \
        "for salesforce case id: #{case_id}")

      restforce_response = []
      result_array = []

      query_string = "SELECT Cost_heading__c " \
        "FROM Project_Cost__c WHERE Case__c = " \
          "'#{case_id}' " \
            "and RecordTypeId = '#{record_type_id}' GROUP BY Cost_heading__c "

      restforce_response = run_salesforce_query(query_string,
        "salesforce_cost_headings", case_id) \
          if query_string.present?

      restforce_response.each do |record|
        result_array.push(record.Cost_heading__c)
      end

      result_array

    end

    # Calls salesforce api helper to get the record type id
    # for a medium grant record type of a project cost record
    # @return [String] a record type id
    def record_type_id_medium_grant_cost

      get_salesforce_record_type_id(
      'Medium_Grants',
      'Project_Cost__c'
      )
      
    end

    # Method to see if an account already has a bank account associated.
    #
    # @param [String] salesforce_account_id Salesforce reference for an org
    # @return [Boolean] (restforce_response.size > 0) 
    #                        True if the org has a bank account in Salesforce
    def org_has_bank_account_in_salesforce(salesforce_account_id)

      Rails.logger.info("Checking for bank account for " \
        "for salesforce account id: #{salesforce_account_id}")

      query_string = "SELECT COUNT() " \
        "FROM Bank_Account__c where Organisation__c = " \
          "'#{salesforce_account_id}'"

      restforce_response = run_salesforce_query(query_string,
        "org_has_bank_account_in_salesforce", salesforce_account_id) \
          if query_string.present?

      restforce_response.size > 0

    end

  end

end
