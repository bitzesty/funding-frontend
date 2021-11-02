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
  # @return [int] summed VAT for costs from sf
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

  # Method to retrive payment percentage cost using sf api
  #
  # @param [SfxPtsPayment] salesforce_case Instance of an  
  #                    object holding info about a Salesforce Experience case
  # @return [int] payment percentage for application
  #       
  def get_payment_percentage(salesforce_case)
    result = []

    sf_api = get_pts_salesforce_api_instance()

    payment_percentage_restforce_response = 
      sf_api.get_payment_percentage(salesforce_case)

    if salesforce_case.application_type = "large_delivery"
      result = payment_percentage_restforce_response.first[:Delivery_payment_percentage__c]
    elsif salesforce_case.application_type = "large_development"
      result = payment_percentage_restforce_response.first[:Development_payment_percentage__c]
    end

    result
  end

  # Method to retrive total VAT cost using sf api
  # 
  #
  # @param [Array] costs An array created by the get_agreed_costs function
  # @return [Float] total_contingency Sum of all the contingency costs
  def get_vat_costs(salesforce_case)
    result = []

    sf_api = get_pts_salesforce_api_instance()

    total_vat_restforce_response = 
      sf_api.get_vat_costs(salesforce_case)

    if salesforce_case.application_type = "large_delivery"
      result = total_vat_restforce_response.first[:Total_delivery_costs_VAT__c]
    elsif salesforce_case.application_type = "large_development"
      result = total_vat_restforce_response.first[:Total_development_costs_VAT__c]
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

  # Deletes a blob using its id
  # @param [blob_id] String A blob Id
  def delete_blob(blob_id)

    blob_id = params[:blob_id]
		logger.info "Removing file with blob id of #{blob_id}"

		# deletes from active_storage_blobs and active_storage_attachments
		attachment_to_delete = ActiveStorage::Attachment.find_by(blob_id: blob_id)
		attachment_to_delete&.purge
    
  end

  # Retrieves the answers json then either:
  # appends a new answer or updates an existing answer
  # then saves
  # @param [json_key] String A string or symbol denoting key in JSON
  # @param [json_value] String What is stored against the json_key  
  def update_pts_answers_json(json_key, json_value)

    json_answers = @salesforce_experience_application.pts_answers_json

    json_answers[json_key] = json_value

    @salesforce_experience_application.pts_answers_json = json_answers
    @salesforce_experience_application.save

  end

  # Clears the answers json for the specified json key:
  # @param [json_key] String A string or symbol denoting key in JSON
  def clear_pts_answers_json_for_key(json_key)

    json_answers = @salesforce_experience_application.pts_answers_json
  
    json_answers.except!(json_key.to_s)

    @salesforce_experience_application.pts_answers_json = json_answers
    @salesforce_experience_application.save

  end

  # Clears the answers json for the specified json key:
  # @param [target_obj] StatutoryPermissionOrLicence An instance
  # @param [json_key] String A string or symbol denoting target key in JSON
  def clear_statutory_permissions_or_licences_json_for_key(target_obj, json_key)

    json_answers = target_obj.details_json
  
    json_answers.except!(json_key.to_s)

    target_obj.details_json = json_answers
    target_obj.save

  end

  # Retrieves the answers json then either:
  # appends a new answer or updates an existing answer
  # then saves
  # @param [target_obj] StatutoryPermissionOrLicence An instance
  # @param [json_key] String A string or symbol denoting key in JSON
  # @param [json_value] String What is stored against the json_key  
  def update_statutory_permissions_or_licences_json(
    target_obj, json_key, json_value)

    target_obj.details_json.nil? ? (json_answers = {}) : \
      (json_answers = target_obj.details_json)

    json_answers[json_key] = json_value

    target_obj.details_json = json_answers
    target_obj.save

  end

  # Uploads all permission to start salesforce experience application
  # TODO: Retries
  # TODO: Persistent queues
  # TODO: Attach to a Large_Grant_Permission_To_Start record, not case
  #
  # @param [salesforce_experience_application] SfxPtsPayment instance
  def upload_salesforce_pts_files(salesforce_experience_application)
    case_id = salesforce_experience_application.salesforce_case_id

    sf_api = get_pts_salesforce_api_instance()

    #Upload all Agreed Cost Evidence files
    salesforce_experience_application.agreed_costs_files.each do |agreed_costs_file|
      sf_api.create_file_in_salesforce(
        agreed_costs_file,
        "Evidence of Agreed Costs -#{agreed_costs_file.blob.filename}",
        case_id
      )
    end

    #Upload all Evidence of Cash Contributions files
    salesforce_experience_application.cash_contributions_evidence_files.each do |cash_contributions_evidence_file|
      sf_api.create_file_in_salesforce(
        cash_contributions_evidence_file,
        "Evidence of Cash Contributions -#{cash_contributions_evidence_file.blob.filename}",
        case_id
       )
    end

    #Upload all Evidence of Fundraising
    salesforce_experience_application.fundraising_evidence_files.each do |fundraising_evidence_file|
      sf_api.create_file_in_salesforce(
        fundraising_evidence_file,
        "Evidence of Fundraising  -#{fundraising_evidence_file.blob.filename}",
        case_id
      )
    end

    #Upload all Evidence of Fundraising files
    salesforce_experience_application.timetable_work_programme_files.each do |timetable_work_programme_file|
      sf_api.create_file_in_salesforce(
        timetable_work_programme_file,
        "Evidence of Timetable Work Programme  -#{timetable_work_programme_file.blob.filename}",
        case_id
      )
    end

    #Upload all Project Management Structure files
    salesforce_experience_application.project_management_structure_files.each do |project_management_structure_file|
      sf_api.create_file_in_salesforce(
        project_management_structure_file,
        "Evidence of Project Management Structure  -#{project_management_structure_file.blob.filename}",
        case_id
      )
    end

    #Upload all Project Management Structure files
    salesforce_experience_application.project_management_structure_files.each do |project_management_structure_file|
      sf_api.create_file_in_salesforce(
        project_management_structure_file,
        "Evidence of Project Management Structure  -#{project_management_structure_file.blob.filename}",
        case_id
      )
    end

    #Upload all Property Ownership files
    salesforce_experience_application.property_ownership_evidence_files.each do |property_ownership_evidence_file|
      sf_api.create_file_in_salesforce(
        property_ownership_evidence_file,
        "Evidence of Property Ownership  -#{property_ownership_evidence_file.blob.filename}",
        case_id
      )
    end

    #Upload all PTS from files
    salesforce_experience_application.pts_form_files.each do |pts_form_file|
      sf_api.create_file_in_salesforce(
        pts_form_file,
        "Permission to Start Form -#{pts_form_file.blob.filename}",
        case_id
      )
    end

   # Upload Statutory Permissions
    salesforce_experience_application.statutory_permission_or_licence.each do |stat_perm|
      stat_perm.upload_files.each do |stat_perm_file|
        sf_api.create_file_in_salesforce(
          stat_perm_file,
          "Evidence of statutory permission or licence -#{stat_perm_file.blob.filename}",
          case_id
        )
      end
    end

  end


  private 

    # Takes a contribution and a boolean to ask whether the contribution 
    # is a cash or non-cash contribution.
    # Upon finding the contribution matches the required type - returns true
    # TODO: Remove the 'Non-cash contributions' values when fix deployed.
    # 
    # @param [source_of_funding] String A salesforce label denoting whether cash
    #                                   or non-cash contribution
    # @param [is_cash_contribution] Boolean True if cash contribution
    #                                       False if non-cash contribution  
    # @return [result] Boolean 
    def filter_contributions(source_of_funding, is_cash_contribution)

      result = nil

      if is_cash_contribution
        result = ['Volunteer Time','Non-cash contributions', 
          'Non cash contributions'].exclude? (source_of_funding) 
      else # is non-cash contribution
        result = ['Volunteer Time','Non-cash contributions', 
          'Non cash contributions'].include? (source_of_funding) 
      end
      
      result

    end

    # This is a common update method used by:
    # StatutoryPermissionOrLicence::ChangeController
    # StatutoryPermissionOrLicence::AddController
    def update_statutory_permission_or_licence

      @statutory_permission_or_licence.validate_date_year_month_day = true
      @statutory_permission_or_licence.validate_licence_type = true
  
      @statutory_permission_or_licence.date_day = 
        permitted_params[:date_day]
      @statutory_permission_or_licence.date_month = 
        permitted_params[:date_month]
      @statutory_permission_or_licence.date_year = 
        permitted_params[:date_year]
      @statutory_permission_or_licence.licence_type = 
        permitted_params[:licence_type.to_s]    
  
      if @statutory_permission_or_licence.valid?
  
        # Form inputs present and correct.  Now check they make a date.
        @statutory_permission_or_licence.validate_licence_date = true
  
        if @statutory_permission_or_licence.valid?
  
          @statutory_permission_or_licence.licence_date = Date.new(
            permitted_params[:date_year].to_i,
            permitted_params[:date_month].to_i,
            permitted_params[:date_day].to_i
          )

          update_statutory_permissions_or_licences_json(
            @statutory_permission_or_licence,
            :licence_type,
            permitted_params[:licence_type.to_s] 
          )

          update_statutory_permissions_or_licences_json(
            @statutory_permission_or_licence,
            :date,
            @statutory_permission_or_licence.licence_date 
          )
          
          @statutory_permission_or_licence.save
  
          logger.info(
            'Applicant has updated statutory_permission_or_licence_id: ' \
              "#{@statutory_permission_or_licence.id} " \
                "for sfx_pts_payment_id: #{@salesforce_experience_application.id}"
          )
  
          redirect_to(
            sfx_pts_payment_statutory_permission_or_licence_files_path(
              @salesforce_experience_application.salesforce_case_id, 
                @statutory_permission_or_licence.id
            )
          )
        
        else
  
          render :show
  
        end
        
      else
  
        render :show
  
      end

    end

end
