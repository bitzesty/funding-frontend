module ApplicationHelper
  require_relative './nlhf_form_builder'
  require 'uri'
  include Project::CalculateTotalHelper

  # Method to take a specified URL and replace or introduce
  # a locale query string equal to the locale string argument 
  # passed into the method
  #
  # @param [string] url     A string representation of a URL
  # @param [string] locale  A string representation of a locale
  def replace_locale_in_url(url, locale)

    parsed_url = URI.parse(url)

    parsed_query_strings = Rack::Utils.parse_query(parsed_url.query)

    parsed_query_strings['locale'] = locale
    parsed_url.query = Rack::Utils.build_query(parsed_query_strings)

    parsed_url.to_s

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
  # @param [String] salesforce_project_reference The Salesforce Case reference
  #                                              to link this upload to
  # @param [String] description A description of the file being uploaded
  def insert_salesforce_attachment(
    client,
    file,
    type,
    salesforce_project_reference,
    description
  )

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

      client.insert!(
        'ContentVersion',
        title: "#{type} File",
        description: description,
        pathOnClient: file.blob.filename,
        versionData: file_upload,
        FirstPublishLocationId: salesforce_project_reference
      )

      Rails.logger.debug(
        "Finished upserting ContentVersion file for #{type} in Salesforce"
      )

    end

  end

end
