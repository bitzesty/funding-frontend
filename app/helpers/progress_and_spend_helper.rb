module ProgressAndSpendHelper
  include SalesforceApi

  # Method responsible for orchestrating the retrieval of
  # additional grant conditions from Salesforce
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  def salesforce_additional_grant_conditions(funding_application)

    client = SalesforceApiClient.new

    case_id = funding_application.salesforce_case_id

    additional_grant_conditions =
      client.additional_grant_conditions \
        (funding_application.salesforce_case_id)

  end

  # Method responsible for getting project expiry date
  # from Salesforce.  Calls project_details on Salesforce
  # Api for code reuse. But could use a dedicated function
  # that only gets expiry if this is too slow.
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  # @return [String] result A grant expiry date
  def salesforce_project_expiry_date(funding_application)

    client = SalesforceApiClient.new

    case_id = funding_application.salesforce_case_id

    project_details =
      client.project_details \
        (funding_application.salesforce_case_id)

    grant_expiry_date = Date.parse(
      project_details.Grant_Expiry_Date__c 
    )

    result = grant_expiry_date.strftime("%d/%m/%Y")

  end

  # Validates and updates procurement model passed in - 
  # parsing date to correct modelformat, checks model valid
  # and calls update. Retruns the passed procurement model. 
  #
  # @param [ProgressUpdateProcurement] procurement An instance of
  #                                                                 ProgressUpdateProcurement
  # @return [ProgressUpdateProcurement] validated and updated procurement
  def validate_and_update_procurement(procurement)
    procurement.date_day = params[:progress_update_procurement][:date_day].to_i
    procurement.date_month = params[:progress_update_procurement][:date_month].to_i
    procurement.date_year = params[:progress_update_procurement][:date_year].to_i

    procurement.validate_date = true

    if procurement.valid?
      params[:progress_update_procurement][:date] = DateTime.new(
        procurement.date_year, 
        procurement.date_month, 
        procurement.date_day 
      )
    end

    procurement.validate_details = true

    procurement.update(get_params)
  end
  
end
