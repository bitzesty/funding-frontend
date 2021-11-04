module PtsSalesforceApi

  # Class to allow interaction with Salesforce via a Restforce client
  class PtsSalesforceApiClient
    include SalesforceApiHelper

    MAX_RETRIES = 3

    # Overrides the .new() method, allowing us to initialise a Restforce client
    # when the SalesforceApiClient class is instantiated
    def initialize

      initialise_client

    end

    # Method to upsert a PTS form files in Salesforce for a Permission to Start application
    #
    # @param [ActiveStorageBlob] file PTS file to upload
    # @param [String] type The type of file to upload (e.g. 'property ownership evidence')
    # @param [String] salesforce_reference The Salesforce Case reference
    #                                              to link this upload to
    # @param [String] description A description of the file being uploaded
    def create_file_in_salesforce(
      file,
      type,
      salesforce_reference,
      description = nil
    )

      Rails.logger.info("Creating #{type} file in Salesforce")

      UploadPtsToSalesforceJob.perform_later(
        file,
        type,
        salesforce_reference,
        description
      )

      Rails.logger.info("Finished creating #{type} file in Salesforce")

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

    # Method to find a Project's approved purposes.
    # If there are no approved purpose, view will inform User.
    # 
    # @param [salesforce_case_id] String A Case Id reference 
    #                                     known to Salesforce 
    # @return [<Restforce::SObject] restforce_response.  A Restforce collection 
    #                                     with query results
    def get_approved_purposes(salesforce_case_id)
      Rails.logger.info("Retrieving Approved Purposes " \
        "for case ID: #{salesforce_case_id}")

      query_string = "SELECT id, Approved_Purposes__c FROM Approved__c " \
        "WHERE Project__c = '#{salesforce_case_id}'"
      
      restforce_response = run_salesforce_query(query_string, 
        "get_approved_purposes", salesforce_case_id)

      restforce_response
    end

    # Method to find a Project's costs by case id and record type.
    #
    # @param [salesforce_case] String A Case Id reference
    #                                     known to Salesforce
    # @return [<Restforce::SObject] restforce_response.  A Restforce collection
    #                                     with query results
    def get_agreed_costs(salesforce_case)
      Rails.logger.info("Retrieving Agreed Costs " \
        "for case ID: #{salesforce_case.salesforce_case_id}")

      restforce_response = []

      query_string = "SELECT Costs__c, Vat__c, Cost_heading__c FROM Project_Cost__c " \
      "WHERE Case__c = '#{salesforce_case.salesforce_case_id}' " \
        "and recordType.DeveloperName = 'Large_Grants_Actual_Delivery'" \
          if salesforce_case.large_delivery?
      
      query_string = "SELECT Costs__c, Vat__c, Cost_heading__c FROM Project_Cost__c " \
      "WHERE Case__c = '#{salesforce_case.salesforce_case_id}' " \
        "and recordType.DeveloperName = 'Large_Grants_Development'" \
          if salesforce_case.large_development?

      restforce_response = run_salesforce_query(query_string, 
        "get_agreed_costs", salesforce_case.salesforce_case_id) \
          if query_string.present?

      restforce_response

    end

    # Method to find a Project's total VAT Cost by case id and record type.
    #
    # @param [salesforce_case] String A Case Id reference
    #                                     known to Salesforce
    # @return [<Restforce::SObject] restforce_response.  A Restforce collection
    #                                     with query results
    def get_vat_costs(salesforce_case)
      Rails.logger.info("Retrieving VAT total Costs " \
        "for case ID: #{salesforce_case.salesforce_case_id}")

      restforce_response = []

      query_string = "SELECT Total_delivery_costs_VAT__c from Case " \
        "WHERE Id = '#{salesforce_case.salesforce_case_id}' "  \
          if salesforce_case.large_delivery? 
      
      query_string = "SELECT Total_development_costs_VAT__c from Case " \
        "WHERE Id = '#{salesforce_case.salesforce_case_id}' "  \
          if salesforce_case.large_development? 
      
      restforce_response = run_salesforce_query(query_string, 
        "get_VAT_total", salesforce_case.salesforce_case_id) \
          if query_string.present?

      restforce_response

    end

    # Method to find a Project's total Payment Percentage by case id and record type.
    #
    # @param [salesforce_case] String A Case Id reference
    #                                     known to Salesforce
    # @return [<Restforce::SObject] restforce_response.  A Restforce collection
    #                                     with query results
    def get_payment_percentage(salesforce_case)
      Rails.logger.info("Retrieving Payment Percentage" \
        "for case ID: #{salesforce_case.salesforce_case_id}")

      restforce_response = []

      query_string = "SELECT Delivery_payment_percentage__c from Case " \
        "WHERE Id = '#{salesforce_case.salesforce_case_id}' "  \
          if salesforce_case.large_delivery? 
      
      query_string = "SELECT Development_payment_percentage__c from Case " \
        "WHERE Id = '#{salesforce_case.salesforce_case_id}' "  \
          if salesforce_case.large_development? 
      
      restforce_response = run_salesforce_query(query_string, 
        "get_payment_percentage", salesforce_case.salesforce_case_id) \
          if query_string.present?

      restforce_response
    end

    # Method to find a Project's incomes by case id and record type.
    #
    # @param [salesforce_case] String A Case Id reference
    #                                     known to Salesforce
    # @return [<Restforce::SObject] restforce_response.  A Restforce collection
    #                                     with query results
    def get_incomes(salesforce_case)
      Rails.logger.info("Retrieving incomes" \
        "for case ID: #{salesforce_case.salesforce_case_id}")

      restforce_response = []
      
      record_type = 'Large_Grants_Actual_Delivery' \
        if salesforce_case.large_delivery?

      record_type = 'Large_Development' \
        if salesforce_case.large_development?

      query_string = "SELECT Source_Of_Funding__c, " \
        "Description_for_cash_contributions__c, Amount_you_have_received__c " \
          "FROM Project_Income__c " \
            "where Case__c = '#{salesforce_case.salesforce_case_id}' " \
              "and recordType.DeveloperName = '#{record_type}' "

      restforce_response = run_salesforce_query(query_string, 
        "get_incomes", salesforce_case.salesforce_case_id) \
          if query_string.present?

      restforce_response

    end


    def create_pts_form_record(salesforce_experience_application) 

      retry_number = 0;

      begin
        salesforce_pts_form_record_id = @client.upsert!(
          'Forms__c',
          'Frontend_External_Id__c',
          Case__c: salesforce_experience_application.salesforce_case_id,
          Frontend_External_Id__c: salesforce_experience_application.id,
          RecordTypeId: get_salesforce_record_type_id('Large_Grants_Permission_To_Start', 'Forms__c')
        )
  
        Rails.logger.info(
          'Created a pts form record in Salesforce with reference: ' \
          "#{salesforce_pts_form_record_id}"
        )

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error(
          'Error creating a PTS for record in Salesforce using ' \
          "funding_application #{funding_application.id}," \
          " user #{user.id} and organisation #{organisation.id}"
        )

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt create_project again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end
      salesforce_pts_form_record_id
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

