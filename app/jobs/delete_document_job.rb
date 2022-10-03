class SalesforceFileDeleteError < StandardError; end

class DeleteDocumentJob < ApplicationJob
  include SalesforceApiHelper
  queue_as :default
  retry_on SalesforceFileDeleteError 

  # Method to delete a Salesforce attachment using
  # Salesforce ContentDocument.Id
  #
  # User does not need to know files are being deleted so can
  # be completed asynchronously.
  #
  # If the Id isn't in Salesforce, no exception is raised. It appears
  # either Restforce or Salesforce handles - so no explicit exception
  # handling needed.
  #
  # @param [string] file_id  ID of ActiveStorage Attachment to destroy
  def perform( 
    file_id)

    initialise_client

    begin

      Rails.logger.info(
        "Attempting to delete ContentDocument Id #{file_id}"
      )

      @client.destroy('ContentDocument', file_id)

      Rails.logger.info(
        "Finished deleting ContentDocument Id #{file_id}"
      )

    rescue Exception => e

      Rails.logger.error("File delete failed for ContentDocument Id " \
        "#{file_id} with error #{e.message}")
      
      raise SalesforceFileDeleteError.new("File delete failed for " \
        "ContentDocument Id #{file_id} with error #{e.message}")
    end

  end

end
