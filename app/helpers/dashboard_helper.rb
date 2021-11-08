module DashboardHelper
  include SalesforceApi
  include FundingApplicationHelper

  # Allows use of the saleslforce_api lib file.  
  # Returns true if a legal agreement is in place
  # The salesforce_api_client is passed in to reduce instances.
  #
  # Todo: At the moment this function will never allowed awards over
  # 100k to begin the payment journey.  This is so that the design can
  # be finished.
  #
  # When payments > 100k can be enabled.  Remove reference to 
  # FundingApplicationHelper and remove the lines indicated by comments below.

  # @param funding_application [FundingApplication] An instance of a 
  #                                                        FundingApplication
  # @param salesforce_api_client [SalesforceApiClient] An instance of 
  #                                                        a SalesforceApiClient
  # @return Boolean True if the project is awarded otherwise false
  def legal_agreement_in_place?(funding_application, salesforce_api_client)
  
    # remove once payments > 100k allowed
    set_award_type(funding_application)

    # Remove "&& !funding_application.is_100_to_250k?" when payments 
    # over 100k allowed 
    if funding_application.submitted_on.present? && 
        !funding_application.is_100_to_250k?

      salesforce_external_id = 
        funding_application.project.present? ? funding_application.project.id : funding_application.id 

        legal_agreement_in_place = salesforce_api_client.legal_agreement_in_place?(salesforce_external_id)

    else

      legal_agreement_in_place = false  

    end

    legal_agreement_in_place

  end

  # Creates and returns an instance of SalesforceApiClient
  # @return SalesforceApiClient [SalesforceApiClient] an instance of this class
  def get_salesforce_api_instance()
    salesforce_api_client= SalesforceApiClient.new
  end 

  # Allows use of the saleslforce_api lib file.  
  # Returns true if the project is awarded
  # Only makes the Salesforce call if the application has a status of submitted.
  # Passes through the project id for small, funding application id otherwise
  # The salesforce_api_client is passed in to reduce instances.
  # TODO - Do not call Salesforce if we have made all payments for an application.
  # @param funding_application [FundingApplication] An instance of a FundingApplication
  # @param salesforce_api_client [SalesforceApiClient] An instance of a SalesforceApiClient
  # @return Boolean True if the project is awarded otherwise false
  def awarded(funding_application, salesforce_api_client)
    if funding_application.submitted_on.present?
      salesforce_external_id = 
        funding_application.project.present? ? funding_application.project.id : funding_application.id
      awarded = salesforce_api_client.is_project_awarded(salesforce_external_id)
    else
      awarded = false  
    end
    awarded
  end

  # Allows use of the saleslforce_api lib file.  
  # Reruns dictionary of large project title and record types registered against user.
  # Passes through email to query sales force contact against.
  # @param salesforce_api_client [SalesforceApiClient] An instance of a SalesforceApiClient
  # @param email [String] An email address.  
  # @return Hash A hash containing two arrays of restforce data.  One for
  #               Delivery applications.  One for Development.
  def get_large_salesforce_applications(salesforce_api_client, email)

    delivery = []
    development = []

    if Flipper.enabled?(:permission_to_start_enabled)

      large_application = 
        salesforce_api_client.select_large_applications(email)

      large_application.each do | app |

        app_hash = {}

        # Set the status of the app_hash, depending on info in the db
        in_progress_app = SfxPtsPayment.find_by(salesforce_case_id: app.Id)

        unless in_progress_app.blank?
          in_progress_app.submitted_on.present? ? \
            app_hash[:status] = t('generic.submitted') : \
              app_hash[:status] = t('generic.in_progress')
        else
          app_hash[:status] = t('generic.not_started')
        end

        # assign app_hash to a RecordType array and add SF info
        if app[:RecordType][:DeveloperName] == "Large"
          app_hash[:salesforce_info] = app
          delivery.push(app_hash)
        end 
        
        if app[:RecordType][:DeveloperName] == "Large_Development_250_500k"
          app_hash[:salesforce_info] = app
          development.push(app_hash)
        end

      end

    end

    return {delivery: delivery, development: development}

  end

end