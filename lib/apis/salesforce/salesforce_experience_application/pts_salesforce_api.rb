module PtsSalesforceApi

  # Class to allow interaction with Salesforce via a Restforce client
  class PtsSalesforceApiClient

    MAX_RETRIES = 3

    # Overrides the .new() method, allowing us to initialise a Restforce client
    # when the SalesforceApiClient class is instantiated
    def initialize

      initialise_client

    end

    # Method to find permission-to-start start page info.
    #
    # @param [salesforce_case_id] String A Case Id reference known to Salesforce
    # @return [<Restforce::SObject>] result&first.  A Restforce object
    #                                               with query results
    def get_info_for_start_page(salesforce_case_id)

      Rails.logger.info("Retrieving permission-to-start start page info " \
        "for case ID: #{salesforce_case_id}")

      query_string = "SELECT Id, Project_Title__c,  " \
        "Project_Reference_Number__c, Grant_Expiry_Date__c, " \
          "Account.name, recordType.DeveloperName " \
            "FROM Case where Id = '#{salesforce_case_id}'"
      
      restforce_response = run_salesforce_query(query_string, 
        "get_info_for_start_page", salesforce_case_id)

      if restforce_response.length == 0

        error_msg = "No permission-to-start start page info for " \
          "salesforce case ID: #{salesforce_case_id}"

        Rails.logger.error(error_msg)

        raise Restforce::NotFoundError.new(error_msg, { status: 500 } )

      end

      restforce_response

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

