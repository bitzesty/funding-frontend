require 'restforce'

include SalesforceApi

class ApplicationToSalesforceJob < ApplicationJob

  include Mailers::GpProjectMailerHelper

  class SalesforceApexError < StandardError; end
  queue_as :default

  # @param [Project] project
  def perform(project)

    logger.info("Submitting Project ID: #{project.id} to Salesforce")

    @json = project.to_salesforce_json

    project.funding_application.update(
      submitted_on: DateTime.now,
      submitted_payload: JSON.parse(@json)
    )

    client = Restforce.new(
        username: Rails.configuration.x.salesforce.username,
        password: Rails.configuration.x.salesforce.password,
        security_token: Rails.configuration.x.salesforce.security_token,
        client_id: Rails.configuration.x.salesforce.client_id,
        client_secret: Rails.configuration.x.salesforce.client_secret,
        host: Rails.configuration.x.salesforce.host,
        api_version: '47.0'
    )

    @response = client.post(
      '/services/apexrest/PortalData',
      @json,
      { 'Content-Type' => 'application/json' }
    )

    @response_body_obj = JSON.parse(@response&.body)

    is_successful = @response_body_obj&.dig('status') == 'Success'

    if(is_successful)

      project.funding_application.update(
        salesforce_case_number: @response_body_obj.dig('caseNumber'),
        salesforce_case_id: @response_body_obj.dig('caseId'),
        project_reference_number: @response_body_obj.dig('projectRefNumber')
      )

      project.user.organisations.first.update(
        salesforce_account_id: @response_body_obj.dig('accountId')
      )

      send_project_submission_confirmation(
        project.user.id,
        project.user.email,
        project.funding_application.project_reference_number
      )

      logger.info
      (
        "Uploading 3-10K files uploaded for case id: " \
        "#{project.funding_application.salesforce_case_id}"
      )
      
      # upload files with salesforce_api_client
      salesforce_api_client = SalesforceApiClient.new

      # Capital Work - only ever one file.
      salesforce_api_client.create_file_in_salesforce(
        project.capital_work_file,
        'Capital Work',
        project.funding_application.salesforce_case_id
      ) if project.capital_work_file.present?

      # Governing document - only ever one file
      salesforce_api_client.create_file_in_salesforce(
        project.governing_document_file,
        'Governing Document',
        project.funding_application.salesforce_case_id
      ) if project.governing_document_file.present?

      # Accounts files, can be more than one, all stored against Project
      salesforce_api_client.create_multiple_files_in_salesforce(
        project.accounts_files,
        'Accounts',
        project.funding_application.salesforce_case_id
      ) if project.accounts_files.any?

      # Project has many cash contributions objects. Each cc has one file.
      project.cash_contributions.each_with_index do |cc, idx|

        salesforce_api_client.create_file_in_salesforce(
          cc.cash_contribution_evidence_files,
          "Cash contribution ##{ idx + 1 }",
          project.funding_application.salesforce_case_id,
          cc.description
        )

      end
      
      # Project has many Evidence of Support objects. Each EOS has one file.
      project.evidence_of_support.each_with_index do |eos, idx|

        salesforce_api_client.create_file_in_salesforce(
          eos.evidence_of_support_files,
          "Evidence of support ##{ idx + 1 }",
          project.funding_application.salesforce_case_id,
          eos.description
        )

      end

      logger.info
      (
        "All 3-10K files uploaded to case id: " \
        "#{project.funding_application.salesforce_case_id}"
      )

      # Consider - this upload functionality could upload each file in its
      # own job for reslience.
      #
      # Example below of how we could call the job.
      #
      # CapitalWorkFileToSalesforceJob.perform_later(
      #   project.id
      # ) if project.capital_work_file.present?
      #
      # Project Id is serialisable, and the job could find the project and
      # upload the file reusing the code above.

    else

      raise SalesforceApexError.new("Failure response from Salesforce when POSTing project ID: #{project.id}, status code: #{@response&.status}")

    end

  end

end
