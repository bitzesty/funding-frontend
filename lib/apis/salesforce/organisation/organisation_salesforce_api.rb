module OrganisationSalesforceApi

  class OrganisationSalesforceApi
    include SalesforceApiHelper

    # Overrides the .new() method, allowing us to initialise a Restforce client
    # when the class is instantiated
    def initialize

      initialise_client

    end

  # Method to retrieve latest org details from salesforce
  #
  # @param [Organisation] organisation The organisation to update.
  # 
  # @return [Hash] restforce_response, Returns ta hash containing salesforce field Keys
  #                            and values. 
    def retrieve_existing_sf_org_details(salesforce_account_id)

      restforce_response = []

      query_string = "SELECT " \
        "Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, " \
          "Company_Number__c, Charity_Number__c, Charity_Number_NI__c, "\
            "Organisation_Type__c, Organisation_s_Mission_and_Objectives__c, " \
              "Are_you_VAT_registered_picklist__c, VAT_number__c, "\
                "Organisation_s_Main_Purpose_Activities__c, " \
                  "Number_Of_Board_members_or_Trustees__c, "\
                    "Social_Media__c, Amount_spent_in_the_last_financial_year__c, " \
                      "level_of_unrestricted_funds__c " \
                        "FROM Account " \
                          "where Id = '#{salesforce_account_id}' " 

      restforce_response = run_salesforce_query(query_string, 
        "retrieve_existing_sf_org_details", salesforce_account_id) \
          if query_string.present?

      restforce_response.first

    end

  end
end
