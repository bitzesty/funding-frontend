module AgreementSalesforceApi

  # Class to allow interaction with Salesforce via a Restforce client
  class AgreementSalesforceApiClient
    include SalesforceApiHelper

    MAX_RETRIES = 3

    # Overrides the .new() method, allowing us to initialise a Restforce client
    # when the AgreementSalesforceApi class is instantiated
    def initialize

      initialise_client

    end
    
    
    # Method to create Contact records in Salesforce for an organisation's
    # legal signatories.
    #
    # @param [LegalSignatory] legal_signatory object
    # @param [String] funding_application A FundingApplication object that 
    #                                     this sig is associated to.
    #
    #@return [String] sig_id A salesforce_id for the record created
    def upsert_signatory_to_salesforce(
      legal_signatory,
      funding_application
    )

      retry_number = 0;

      begin
        sig_id = @client.upsert!(
          'Legal_Signatory__c',
          'Legal_Signatory_External_ID__c',
          Email__c: legal_signatory.email_address,
          Legal_Signatory_External_ID__c: legal_signatory.id,
          Name__c: legal_signatory.name,
          Project__c: funding_application.salesforce_case_id,
          Role__c: legal_signatory.role
        )

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error(
          'Error creating a Legal_Signatory__c record in Salesforce using ' \
            "funding_application ID:  #{funding_application.id}," \
              " and legal_signatory ID:  #{legal_signatory.id}"
        )

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt upsert_signatory_to_salesforce again, " \
              "retry number #{retry_number} " \
                "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

      Rails.logger.info(
        'Created a signatory record in Salesforce with reference: ' \
          "#{sig_id}"
      )

      sig_id

    end


    # Consider moving to some kind of helper.  Or write methods in an 
    # abstract class that each of these classes inherit from.
    private

    # Method to initialise a new Restforce client, called as part of object
    # instantiation
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
