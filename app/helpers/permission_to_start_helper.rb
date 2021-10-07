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

  # Method to find and transform approved purposes from salesforce.
  # Transforms restforce collection into a testable array.
  #
  # @param [salesforce_case_id] String A Case Id reference known to Salesforce
  # @return [Array] formatted_start_page_info A hash with formatted info
  #       
  def get_approved_purposes(salesforce_case_id)

    result = []

    sf_api = get_pts_salesforce_api_instance()

    approved_purposes_restforce_collection = 
      sf_api.get_approved_purposes(salesforce_case_id)

    approved_purposes_restforce_collection.each do |ap|
      result.push(ap[:Approved_Purposes__c])
    end

    result

  end

  # Method to find and transform agreed costs from salesforce.
  # Transforms restforce collection into a testable array.
  # Convert values to float. This will change nil values to zero.
  #
  # @param [SfxPtsPayment] salesforce_case Instance of an  
  #                    object holding info about a Salesforce Experience case
  # @return [Array] formatted_start_page_info A hash with formatted info
  #       
  def get_agreed_costs(salesforce_case)
    result = []

    sf_api = get_pts_salesforce_api_instance()

    agreed_costs_restforce_collection = 
      sf_api.get_agreed_costs(salesforce_case)

    total_contingency = 0

    agreed_costs_restforce_collection.each do |ac|

      result.push({
        cost_heading: ac[:Cost_heading__c],
        cost: ac[:Costs__c].to_f,
        vat: ac[:Vat__c].to_f,
        total: ac[:Vat__c].to_f + ac[:Costs__c].to_f
        })
    end

    result
  end

  # Method to iterate over a collection of costs and create a sum of all the
  # Contingency costs to display on the agreed costs form
  # 
  # The costs param is an array created by the get_agreed_costs function
  #
  # @param [Array] costs An array created by the get_agreed_costs function
  # @return [Float] total_contingency Sum of all the contingency costs
  def get_total_contingency(costs) 

    total_contingency = 0

    costs.each do |cost| 
      if cost[:cost_heading] == "Contingency"
        total_contingency += cost[:total].to_f
      end
    end

    total_contingency
  end

  # Method to identify the type of large application when it
  # Comes from Salesforce experience.
  #
  # Assigns to the application_type attribute of the SfxPtsPayment instance
  #
  # @param [SfxPtsPayment] salesforce_case Instance of an  
  #                    object holding info about a Salesforce Experience case
  def set_application_type(salesforce_case)

    salesforce_case.application_type = :unknown

    start_page_info = get_info_for_start_page \
      (salesforce_case.salesforce_case_id)

    if start_page_info[:large_application_type] == 'Delivery'
      salesforce_case.application_type = :large_delivery
    end

    if start_page_info[:large_application_type] == 'Development'
      salesforce_case.application_type = :large_development
    end
     
    if salesforce_case.unknown?
      raise StandardError.new(
        "Could not identify an application type for: " \
          "#{salesforce_case.salesforce_case_id}"
      )
  
    end

  end

  # Method to get contributions for review by the applicant
  # Comes from Salesforce experience.  This function transforms
  # an filters a restforce collection into a testable array.
  # Caution - Salesforce queries return picklist labels NOT 
  # API names as docs specify.  Means SF label changing could
  # break this.
  # 
  # @param [salesforce_case_id] String A Case Id reference known to Salesforce
  # @param [is_cash_contribution] Boolean True if cash contribution
  #                                       False if non-cash contribution  
  # @return [Array] result An array contain hashes for each 
  #                                            contribution
  def get_contributions(salesforce_case, is_cash_contribution)

    result = []

    sf_api = get_pts_salesforce_api_instance()

    contributions_restforce_collection = 
      sf_api.get_incomes(salesforce_case)

    contributions_restforce_collection.each do |contribution|
      if filter_contributions(contribution[:Source_Of_Funding__c], is_cash_contribution)
        result.push(
          {
            description_of_funding: \
              contribution[:Description_for_cash_contributions__c], 
            amount_expected: contribution[:Amount_you_have_received__c].to_f
          }
        )
      end
    end

    result

  end

  private 

    # Takes a contribution and a boolean to ask whether the contribution 
    # is a cash or non-cash contribution.
    # Upon finding the contribution matches the required type - returns true.
    # 
    # @param [source_of_funding] String A salesforce label denoting whether cash
    #                                   or non-cash contribution
    # @param [is_cash_contribution] Boolean True if cash contribution
    #                                       False if non-cash contribution  
    # @return [result] Boolean 
    def filter_contributions(source_of_funding, is_cash_contribution)

      result = nil

      if is_cash_contribution
        result = ['Volunteer Time','Non-cash contributions'].exclude? (source_of_funding) 
      else # is non-cash contribution
        result = ['Volunteer Time','Non-cash contributions'].include? (source_of_funding) 
      end
      
      result

    end

end
