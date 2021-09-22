module PermissionToStartHelper
  include PtsSalesforceApi

  # Creates and returns an instance of SalesforceApiClient
  # @return SalesforceApiClient [SalesforceApiClient] an instance of this class
  def get_pts_salesforce_api_instance()
    pts_salesforce_api_client= PtsSalesforceApiClient.new
  end 

  # Method to find and transform permission-to-start start page info.
  # Date and large application types are transformed.
  #
  # @param [salesforce_case_id] String A Case Id reference known to Salesforce
  # @return [Hash] formatted_start_page_info A hash with formatted info
  #                                               
  def get_info_for_start_page(salesforce_case_id)

    sf_api = get_pts_salesforce_api_instance()
    salesforce_info_for_start_page = 
      sf_api.get_info_for_start_page(salesforce_case_id).first

    grant_expiry_date_string = ''

    unless salesforce_info_for_start_page.Grant_Expiry_Date__c.blank?
      grant_expiry_date = Date.parse(salesforce_info_for_start_page.Grant_Expiry_Date__c)
      grant_expiry_date_string = grant_expiry_date.strftime("%d/%m/%Y")
    end

    if salesforce_info_for_start_page[:RecordType][:DeveloperName] \
      == "Large"
      large_application_type = 'Delivery'
    end 
    
    if salesforce_info_for_start_page[:RecordType][:DeveloperName] \
      == "Large_Development_250_500k"
      large_application_type = 'Development'
    end

    formatted_start_page_info = 
      {
        org_name: salesforce_info_for_start_page.Account.Name,
        grant_expiry_date: grant_expiry_date_string,
        project_ref_no: 
          salesforce_info_for_start_page.Project_Reference_Number__c,
        project_title: salesforce_info_for_start_page.Project_Title__c,
        large_application_type: large_application_type
      }

  end

end
