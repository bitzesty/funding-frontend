module ProgressUpdateSalesforceApi

  # Class to allow interaction with Salesforce via a Restforce client
  class ProgressUpdateSalesforceApiClient
    include SalesforceApiHelper

    MAX_RETRIES = 3

    # Overrides the .new() method, allowing us to initialise a Restforce client
    # when the AgreementSalesforceApi class is instantiated
    def initialize

      initialise_client

    end
   
    # Method to find a cash contribution by id.
    #
    # @param [String] id An Id reference known to Salesforce
    # @return [<Restforce::SObject] restforce_response.  A Restforce collection
    #                                     with query results
    def get_medium_cash_contribution(salesforce_project_income_id)
      Rails.logger.info("Retrieving cash contribution aka project income" \
        "for Id: #{salesforce_project_income_id}")

      restforce_response = []

      query_string = "SELECT " \
        "Description_for_cash_contributions__c, Amount_you_have_received__c " \
          "FROM Project_Income__c " \
            "where Id = '#{salesforce_project_income_id}' " \
              "and recordType.DeveloperName = 'Delivery' "

      restforce_response = run_salesforce_query(query_string, 
        "get_medium_cash_contribution", salesforce_project_income_id) \
          if query_string.present?

      restforce_response

    end

    # Method to find the number of cash contributions for a project.
    #
    # @param [String] id A Project Id reference known to Salesforce
    # @return [Integer] restforce_response.size.  Number found
    def cash_contribution_count(salesforce_case_id)
      Rails.logger.info("Retrieving cash contribution count" \
        "for Case Id: #{salesforce_case_id}")

      restforce_response = []

      query_string = "SELECT COUNT() from Project_Income__c " \
        "where Case__c = '#{salesforce_case_id}'"

      restforce_response = run_salesforce_query(query_string, 
        "cash_contribution_count", salesforce_case_id) \
          if query_string.present?

      restforce_response.size

    end

    private


    # Method to initialise a new Restforce client, called as part of object instantiation
    def initialise_client

      Rails.logger.info('Initialising Salesforce client')

      retry_number = 0
      
      begin

        @client = Restforce.new(
          username: Rails.configuration.x.salesforce.username,
          password: Rails.configuration.x.salesforce.password,
          security_token: Rails.configuration.x.salesforce.security_token,
          client_id: Rails.configuration.x.salesforce.client_id,
          client_secret: Rails.configuration.x.salesforce.client_secret,
          host: Rails.configuration.x.salesforce.host,
          api_version: '47.0'
        )

        Rails.logger.info('Finished initialising Salesforce client')

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt to initialise_client again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep(rand(0..max_sleep_seconds))

          retry

        else

          raise

        end

      end

    end
    
    # Method to run a salesforce query with MAX_RETRIES.
    #
    # @param [query_string] String The query to be run
    # @param [calling_function_name] String Name of calling function
    # @param [log_safe_id] String A unique id. But no personal info.
    # @return [<Restforce::SObject>] result&first.  A Restforce object
    #                                               with query results
    def run_salesforce_query(query_string, calling_function_name,
      log_safe_id)
      
      retry_number = 0

      begin

        restforce_response = @client.query(query_string)

        restforce_response

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
              Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error(
          "Exception occured in #{calling_function_name}, with log_safe_id: " \
            "#{log_safe_id} (#{e})"
        )

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt #{calling_function_name} with log_safe_id: " \
              "#{log_safe_id} again, retry number #{retry_number} " \
                "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

  end

end

