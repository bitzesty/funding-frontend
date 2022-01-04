class SalesforceFileUploadError < StandardError; end
# Module to contain all the common saleforce utilities used by PtsSalesforceApi and SalesforceApi
module SalesforceApiHelper

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
        @client.query_all("select Id, SObjectType from RecordType where DeveloperName = '#{developer_name}' " \
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

end
