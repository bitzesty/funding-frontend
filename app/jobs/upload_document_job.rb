class SalesforceFileUploadError < StandardError; end

class UploadDocumentJob < ApplicationJob
  queue_as :default
  retry_on SalesforceFileUploadError 

  # Method to insert a Salesforce document using Restforce
  #
  # This is the perform job method that adds the upload files to a queue to 
  # be completed asynchronously . 
  #
  # @param [ActiveStorage::Attachment] file An ActiveStorage Attachment
  # @param [String] type The type of file being inserted
  # @param [String] salesforce_reference The Salesforce Case/Form reference
  #                                              to link this upload to
  # @param [String] description A description of the file being uploaded
  # @param [ApplicationRecord] owning_record Record the file is associated to
  def perform( 
    file,
    type,
    salesforce_reference,
    description,
    owning_record = nil
  )

    initialise_client

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
          content_version_id = @client.insert!(
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

          update_owning_record_with_file_id(
            content_version_id,
            owning_record
          ) if owning_record.present?

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

  private 

  def initialise_client()
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

  # Only suitable for HighSpends instances at the time of writing.
  #
  # Checks that the owning_record has an attribute for
  # salesforce_content_document_ids - see HighSpends as example.
  # Then initialises if nil and pushes the content version id to the array.
  #
  # This can be used later to see which SF files came from this HighSpend.
  #
  # @param [String] content_version_id Id for content version returned from SF
  # @param [ApplicationRecord] owning_record Instance of HighSpend (for now)
  def update_owning_record_with_file_id(content_version_id, owning_record)

    if owning_record&.has_attribute?(:salesforce_content_document_ids)

      logger.info(
        "File uploaded for #{owning_record.class.name} with id " \
          "#{owning_record.id}. Content version Id is #{content_version_id}."
      )

      # We insert documents by content version.  But we can't delete by content
      # version Id.  So get and store the document Id instead.
      content_document_id = @client.select(
        'ContentVersion',
        content_version_id,
        ["ContentDocumentId"],
        'Id'
      ).ContentDocumentId

      owning_record.salesforce_content_document_ids = [] if
        owning_record.salesforce_content_document_ids.nil?

      owning_record.salesforce_content_document_ids.push(content_document_id)
      owning_record.save!

    else

      logger.error(
        "#{owning_record.class.name} with id #{owning_record.id} has no " \
          "salesforce_content_document_ids attribute. Content document Id is " \
            "#{content_document_id}.  But this has not been stored."
      )

    end

  end

end