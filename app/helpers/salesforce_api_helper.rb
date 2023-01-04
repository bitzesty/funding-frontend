class SalesforceFileUploadError < StandardError; end
# Module to contain all the common saleforce utilities used by PtsSalesforceApi and SalesforceApi
module SalesforceApiHelper

  MAX_RETRIES = 3

  # Method check Salesforce for a correct RecordType Id
  # A Salesforce Id for the RecordType is returned if a match is made. 
  # Otherwise a not found exception is raised.
  #
  # exceptions and retries should be handled in calling function.
  #
  # @param [String] developer_name An salesforce Developername for a RecordType
  # @param [String] object_type An salesforce SobjectType for a RecordType
  #
  # @return [String] record_type_id&.first&.Id The RecordType.Id found
  def get_salesforce_record_type_id(developer_name, object_type)    

    record_type_id = 
      @client.query("select Id, SObjectType from RecordType where DeveloperName = '#{developer_name}' " \
                        "and SObjectType = '#{object_type}'")

    if record_type_id.length != 1

      error_msg = "No RecordType found for DeveloperName: #{developer_name} and SObjectType: #{object_type}"

      Rails.logger.error(error_msg)

      raise Restforce::NotFoundError.new(error_msg, { status: 500 } )

    end

    record_type_id&.first&.Id

  end

  # Method to insert a Salesforce attachment using Restforce
  #
  # This method lives here, as opposed to the SalesforceApi lib class as
  # it's not possible to call the .open method from within the lib class,
  # as this is a private method, only available in controllers, helpers,
  # etc.
  #
  # @param [Restforce::Client] client An instance of a Restforce client
  # @param [ActiveStorage::Attachment] file An ActiveStorage Attachment
  # @param [String] type The type of file being inserted
  # @param [String] salesforce_reference The Salesforce Case reference
  #                                              to link this upload to
  # @param [String] description A description of the file being uploaded
  def insert_salesforce_attachment(
    client,
    file,
    type,
    salesforce_reference,
    description
  )

    begin
      file.open do |f|

        Rails.logger.debug(
          "Creating Restforce::UploadIO object for #{type} file"
        )

        file_upload = Restforce::UploadIO.new(f.path, file.content_type)

        Rails.logger.debug(
          "Finished creating Restforce::UploadIO object for #{type} file"
        )

        Rails.logger.debug(
          "Upserting ContentVersion file for #{type} in Salesforce"
        )

        if file.blob.byte_size > 0 
          client.insert!(
            'ContentVersion',
            title: "#{type} File",
            description: description,
            pathOnClient: file.blob.filename,
            versionData: file_upload,
            FirstPublishLocationId: salesforce_reference
          )

          Rails.logger.debug(
            "Finished upserting ContentVersion file for #{type} in Salesforce"
          )
        else
          Rails.logger.error(
            "Cannot upload empty file #{file.blob.filename} in Salesforce - file is of size 0 bytes"
          )
          raise Exception.new "Cannot upload empty file #{file.blob.filename} in Salesforce - file is of size 0 bytes"
        end

      end
    rescue Exception => e
      Rails.logger.error("File upload failed for file #{file.blob.filename} on Salesforce Case ID / 
        #{salesforce_reference} with error #{e.message}")
        
      raise SalesforceFileUploadError.new("File upload failed for file #{file.blob.filename} on Salesforce Case ID / 
          #{salesforce_reference} with error #{e.message}")
    end

  end

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

  # Returns I18n translation for a salesforce cost heading.
  # If the translation is not found, then log as an error and
  # return the passed string as a result.
  #
  # A MissingTranslationData error will occur is a new cost
  # type is added to Salesforce without updating the salesforce_text ymls
  #
  # @param [String] heading A Salesforce cost heading
  # @return [String] result The translated cost heading
  def translate_salesforce_cost_heading(heading)

    result = heading # use what is already there in event of error.

    begin

      result = t(
        "salesforce_text.project_costs.#{heading.parameterize.underscore}",
        :raise => I18n::MissingTranslationData
      )

    rescue I18n::MissingTranslationData => e

      Rails.logger.error("translation missing error in translate_heading " \
        "method. Error is #{e.message}")

    end

    result

  end

  # Returns payment reference if present on bank details,
  # if not provided then queries previous payment requests for  
  # reference.
  #
  #
  # @param [FundingApplication] funding_application 
  # @return [String] payment_ref The payment reference found
  def get_payment_reference(funding_application)

    retry_number = 0
    
    begin
      payment_ref = funding_application.payment_details&.decrypt_payment_reference

      if payment_ref.nil?

        pymnt_rqst_rcrd_type_id = 
          get_salesforce_record_type_id(
            'Payment_Request', 
            'Forms__c'
          )

        prg_updt_pymnt_rqst_rcrd_type_id = 
          get_salesforce_record_type_id(
            'Payment_Request_and_Project_Update', 
            'Forms__c'
          )

        previous_payment_request_ref =  @client.query(
          "SELECT Payment_Reference_number__c, CreatedDate FROM Forms__c WHERE "\
            "(RecordTypeID = '#{pymnt_rqst_rcrd_type_id}' OR "\
              "RecordTypeID = '#{prg_updt_pymnt_rqst_rcrd_type_id}' ) "\
                "AND Case__c = '#{funding_application.salesforce_case_id}' "\
                  "order by CreatedDate desc Limit 1")

        payment_ref = previous_payment_request_ref.first&.Payment_Reference_number__c

      end

    rescue Exception => e
      if retry_number < MAX_RETRIES

        retry_number += 1

        max_sleep_seconds = Float(2 ** retry_number)

        Rails.logger.info(
          "Error retrieving payment reference for application with id:"\
            "#{funding_application.salesforce_case_id} " \
              "will attempt again, retry number #{retry_number} " \
                "after a sleeping for up to #{max_sleep_seconds} seconds"
        )

        sleep rand(0..max_sleep_seconds)

        retry

      else
        raise
      end
    end

    payment_ref

  end

  # Returns an array of Salesforce document IDs that match a provided filename,
  # and have been uploaded against a specific linked entity (Form or Case). 
  #
  #
  # @param [String] file_name 
  # @param [String] salesforce_linked_entity_id 
  # @return [ Array[String] ] matching_file_ids IDs of matching documents
  def get_existing_files_in_salesforce(salesforce_linked_entity_id, file_name)
    retry_number = 0     

    begin

      matching_file_ids = []

      # replaces single apostrophe with escaped apostrophe 
      # using a backslash when escaped_filename put out.
      # Required so the SOQL call will run.
      escaped_filename = file_name.gsub("'", "\\\\'")
      
      document_link_ids =
        @client.query("SELECT ContentDocumentId FROM "\
          "ContentDocumentLink where LinkedEntityId = '#{salesforce_linked_entity_id}'")      

      document_link_ids.each do | doc_id |  

        query_string = "SELECT Id "\
        "FROM ContentDocument where " \
          "Id = '#{doc_id.ContentDocumentId}' AND "\
            "Title = '#{escaped_filename}' AND IsDeleted = false AND IsArchived = false"

        doc =  @client.query(query_string)
     
        if doc.size > 0 
          matching_file_ids.push(doc.first.Id) 
          
          Rails.logger.info("Document with id #{doc.first.Id}"\
            "found against link entity #{salesforce_linked_entity_id} " )

        end
        
      end

      matching_file_ids
    
    rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
      Restforce::EntityTooLargeError, Restforce::ResponseError => e

      Rails.logger.error("Error checking for existing  document id" \
        "with link entity id: #{salesforce_linked_entity_id}")

      # Raise and allow global exception handler to catch
      raise

    rescue Timeout::Error, Faraday::ClientError => e

      if retry_number < MAX_RETRIES

        retry_number += 1

        max_sleep_seconds = Float(2 ** retry_number)

        Rails.logger.info(
          "Will attempt to retrieve existing document id , "\
            "retry number #{retry_number} " \
              "after a sleeping for up to #{max_sleep_seconds} seconds"
        )

        sleep rand(0..max_sleep_seconds)

        retry

      else

        raise

      end

    end

  end

  # Uses the salesforce_text yamls to convert a heading back to salesforce
  # picklist format.
  # If the heading is English, it should already be in salesforce format.
  # If the heading is Welsh, the English salesforce format is used.
  # If the heading is not found in either yaml - we return it unchanged.
  #
  # @param [String] heading A cost heading stored FFE-side
  # @param [Hash] en_hash Hash containing cost headings in English
  # @param [Hash] cy_hash Hash containing cost headings in Welsh
  # @return [String] result The cost heading, in Salesforce picklist format
  #
  def convert_cost_heading_to_salesforce_picklist(heading, en_hash, cy_hash)

    # See if the value is in the English hash - if so return.
    if en_hash.has_key?(heading.parameterize.underscore)

      return heading

    end

    # See if the value is in the Welsh hash. If so, use the key to
    # get the English value - and return.
    if cy_hash.has_value?(heading)
      yaml_key = cy_hash.key(heading)
      return en_hash[yaml_key]
    end

    # If the string matches no hashes, return the original string.  Could
    # be that FFE is not updated with a new picklist value yet.  Must be a
    # valid picklist value, or subsequent upsert to Salesforce will fail.
    heading

  end

  # Converts /salesforce_text/en.yml into a hash
  # This can be used to convert translations.
  def get_en_cost_headings

    en_hash =
      YAML.load_file(
        'config/locales/salesforce_text/en.yml'
      )["en-GB"]["salesforce_text"]["project_costs"]

  end

  # Converts /salesforce_text/cy.yml into a hash
  # This can be used to convert translations.
  def get_cy_cost_headings

    cy_hash =
      YAML.load_file(
        'config/locales/salesforce_text/cy.yml'
      )["cy"]["salesforce_text"]["project_costs"]

  end

end
