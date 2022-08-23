module DashboardHelper
  include SalesforceApi
  include FundingApplicationHelper

  # Allows use of the salesforce_api lib file.
  # Returns true if a legal agreement is in place
  # The salesforce_api_client is passed in to reduce instances.
  #
  # For performance, ensure this is only called for submitted applications.
  #
  # @param [String] salesforce_case_id Salesforce ref for a case
  # @param [SalesforceApiClient] salesforce_api_client An instance of
  #                                                       a SalesforceApiClient
  # @return Boolean True if the project is awarded otherwise false
  def legal_agreement_in_place?(salesforce_case_id, salesforce_api_client)
  
    legal_agreement_in_place =
      salesforce_api_client.legal_agreement_in_place?(
        salesforce_case_id
      )

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
  # @param [SalesforceApiClient] salesforce_api_client An instance of a SalesforceApiClient
  # @param [String] email An email address.  
  # @return [Hash] A hash containing two arrays of restforce data.  One for
  #               Delivery applications.  One for Development.
  def get_large_salesforce_applications(salesforce_api_client, email)

    delivery = []
    development = []

    if Flipper.enabled?(:permission_to_start_enabled)

      large_application = 
        salesforce_api_client.select_large_applications(email)

      large_application.each do | app |

        app_hash = {}

        app_hash[:status] = find_status_for_large_project(
          app.Id,
          salesforce_api_client
        )

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

  # Returns an I18n string for the status of the large project.
  #
  # Firstly looks for projects where payments have started.
  # Projects spend most of their time at this 'In progress' status.
  # Requires a quick pg check. If a FundingApplication instance with a status
  # of payment_can_start? is found, return  the 'In progress' status if
  # payments are found, else return 'Not started' if no payments exist yet.
  #
  # Secondly looks for permission to start instances that haven't been
  # submitted and does this with pg.  Returns 'Not started' if no SfxPtsPayment
  # instance is found.  Or 'In progress' if found and not submitted.
  #
  # Thirdly looks at Projects which have a submitted SfxPtsPayment instance,
  # but no FundingApplication instance with a payment status. Check Salesforce
  # to see if the legal agreement is in place.  If in place, status is
  # 'Not started', as payment can start.  Else the status remains as Submitted
  #
  # Defaults to In progress, and logs error if status can't be identified.
  # Does not cause exception.
  #
  # TLDR, statuses in chronologoical order:
  # - If no permission to start instance found, status is 'Not started'
  # - If permission to start begun, but not submitted, its 'In progress'
  # - If permission to start submitted, its 'Submitted'
  # - If permission to start is processed in Salesforce, then 'Not started'
  # - If the payment journey has started, then 'In progress'
  # - In the event of an error - defaults to 'In progress'
  #
  # @param [String] salesforce_case_id Salesforce reference for a project
  # @param [SalesforceApiClient] salesforce_api_client An instance of a 
  #                                                       SalesforceApiClient
  # @return [String] status. An I18n string for status.
  def find_status_for_large_project(salesforce_case_id, salesforce_api_client)

    # In progress if funding application exists and payment can start
    fa = FundingApplication.find_by(salesforce_case_id: salesforce_case_id)
    if fa&.payment_can_start?

      if fa.payment_requests.any?

        return t('generic.in_progress')

      else

        return t('generic.not_started')

      end

    end

    # Not started, or In progress.  Depends on permission to start progress.
    pts = SfxPtsPayment.find_by(salesforce_case_id: salesforce_case_id)
    if pts.nil?

      return t('generic.not_started')

    elsif pts.present? && pts.submitted_on.blank?

      return t('generic.in_progress')

    end

    # Permission to start is submitted.  Check if payment can start.
    if legal_agreement_in_place?(
      salesforce_case_id,
      salesforce_api_client
      )

      return t('generic.not_started')

    else

      return t('generic.submitted')

    end

    # Default to In progress - status could not be identified.
    Rails.logger.error("Large progress status could not be identified for " \
      "salesforce_case_id #{salesforce_case_id}")

    return t('generic.in_progress')

  end

  # Finds an existing, or gets a new FundingApplication for
  # a large grant. Should only be called when a large grant
  # is ready for an arrears payment.
  #
  # If it finds an existing FundingApplication, immediately
  # returns it.
  #
  # If no FundingApplication found, check that the passed
  # large_project_salesforce_account_id is valid, then create
  # a new FundingApplication if so.
  #
  # If FFE has an org with a different salesforce_account_id, this is a
  # support issue.  Log and return nil for the FundingApplication.
  # Calling method handles this when no FundingApplication provided.
  #
  # @param [String] salesforce_case_id Salesforce ref for a large project
  # @param [String] large_project_salesforce_account_id Salesforce ref 
  #                                                        for a large Org
  # @param [String] submission_date Date the large application was submitted
  # @param [SalesforceApiClient] salesforce_api_instance An existing connection
  #                                                           to Salesforce
  # @return [FundingApplication] funding_application for large project, or
  #                   nil if a FundingApplication can't be found or created
  def get_large_funding_application(salesforce_case_id,
    large_project_salesforce_account_id, submission_date,
      salesforce_api_instance)

    funding_application = FundingApplication.find_by(
      salesforce_case_id: salesforce_case_id
    )

    if funding_application.nil?

      if valid_salesforce_account_id?(large_project_salesforce_account_id)

        pts_submitted_date =
          SfxPtsPayment.find_by(
            salesforce_case_id: salesforce_case_id
          ).submitted_on

          project_reference_num = 
            salesforce_api_instance
              .get_external_reference_number_for_project(salesforce_case_id)

        funding_application = FundingApplication.create(
          organisation_id: current_user.organisations.first.id,
          salesforce_case_id: salesforce_case_id,
          submitted_on: submission_date,
          project_reference_number: project_reference_num,
          agreement_submitted_on: pts_submitted_date
        )

        check_award_type(funding_application)

        funding_application.update(status: :payment_can_start)
      
      else

        Rails.logger.error(
          "Large project #{salesforce_case_id} uses " \
            "salesforce_account_id: #{large_project_salesforce_account_id} " \
              "whereas the org for current user #{current_user.id} uses " \
                "salesforce_account_id: " \
                  "#{current_user.organisations.first.salesforce_account_id}" \
                    ". so FundingApplication not created."
        )

      end

    end

    funding_application

  end

  # Looks at the current user's org see see if a salesforce_account_id
  # exists.  
  #
  # If not, updates FFE's org record with the salesforce_account_id
  # from the Large application.  The Organisation model will retrieve the
  # rest of the information using its after_find hook
  #
  # If so, returns true if the salesforce_account_id on the existing FFE
  # org record and large_project_salesforce_account_id match,
  #
  # @param [String] large_project_salesforce_account_id Salesforce_account_id
  #                                                 linked to a Large Project
  # @return [Boolean] True if large_project_salesforce_account_id valid
  def valid_salesforce_account_id?(large_project_salesforce_account_id)

    if current_user.organisations.first.salesforce_account_id.nil?

      current_user.organisations.first.update(
        salesforce_account_id: large_project_salesforce_account_id
      )

      return true

    end

    if current_user.organisations.first.salesforce_account_id.present?

      return current_user.organisations.first.salesforce_account_id == \
        large_project_salesforce_account_id

    end

  end

  # Helper method that calls salesforce_api to retrieve large project title.
  #
  # @param [SalesforceApi] salesforce_api_client Instance of 
  #                                   salesforce_api used to call query method
  # @param [String] salesforce_case_id salesforce case id of project 
  # 
  # @return [String] project_title project title for given case with 
  #                                   salesforce_case_id
  def get_large_project_title(salesforce_api_client, salesforce_case_id)
    project_title = salesforce_api_client
      .get_project_title(salesforce_case_id).Project_Title__c
  end

end
