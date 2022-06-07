module ProgressAndSpendHelper
  include SalesforceApi
  include ProgressUpdateSalesforceApi
  include PaymentRequestSalesforceApi
  include FundingApplicationHelper
  include Enums::ArrearsJourneyStatus

  MAX_RETRIES = 3

  # Method responsible for orchestrating the retrieval of
  # additional grant conditions from Salesforce
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  # @return [<Restforce::SObject] additional_grant_conditions.
  #                      A Restforce collection with query results
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

  # Method responsible for getting details related to a project
  # required for arrears from Salesforce.  
  # Calls project_details on Salesforce
  # API method for code reuse.
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  # @return [Hash] result Project data required for arrears
  def salesforce_arrears_project_details(funding_application)

    client = ProgressUpdateSalesforceApiClient.new

    case_id = funding_application.salesforce_case_id

    arrears_heading_info =
      client.arrears_heading_info \
        (funding_application.salesforce_case_id)

    details_hash = {}

    grant_expiry_date = Date.parse(
      arrears_heading_info.Grant_Expiry_Date__c 
    )

    details_hash[:project_name] = arrears_heading_info.Project_Title__c
    details_hash[:project_expiry_date] = grant_expiry_date.strftime("%d/%m/%Y")
    details_hash[:amount_paid] = arrears_heading_info.Total_Payments_Paid__c
    details_hash[:amount_remaining] = arrears_heading_info.Remaining_Grant__c
    details_hash[:payment_percentage] = arrears_heading_info.payment_percentage__c

    details_hash
    
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

  # Returns the permitted params
  #
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def risk_permitted_params(params)

    params.require(:progress_update_risk).permit(
      :id,
      :description,
      :likelihood,
      :impact,
      :is_still_risk,
      :yes_still_a_risk_description,
      :no_still_a_risk_description,
      :is_still_risk_description
    )
  end

  # Uses a ternary to evaluate whether the applicant has indicated a
  # resolved or ongoing risk.
  # Then adds a new param for is_still_risk_description using either
  # yes_still_a_risk_description or no_still_a_risk_description
  #
  # @params [ProgressUpdateRisk] risk
  # @params [ActionController::Parameters] params Unfiltered params
  def assign_is_still_risk_description_param(risk, params)

    pp = risk_permitted_params(params)

    pp[:is_still_risk] == true.to_s ? \
      params[:progress_update_risk][:is_still_risk_description] = \
        pp[:yes_still_a_risk_description] :\
          params[:progress_update_risk][:is_still_risk_description] = \
            pp[:no_still_a_risk_description]

  end

  # Evaluates whether the applicant has indicated a
  # resolved or ongoing risk.
  # Toggles appropriate validation so that either
  # validate_yes_still_a_risk_description or
  # validate_no_still_a_risk_description is validated
  #
  # @params [ProgressUpdateRisk] risk
  # @params [ActionController::Parameters] params Unfiltered params
  def toggle_risk_validation(risk, params)

    pp = risk_permitted_params(params)

    pp[:is_still_risk] == true.to_s ? \
      risk.validate_yes_still_a_risk_description = true :\
         risk.validate_no_still_a_risk_description = true

  end

  # Retrieves medium cash contributions from Salesforce
  # Only suited for for medium application < 250001 at the moment and
  # returns Description_for_cash_contributions__c for display.
  # 
  # Large applications will require a new function that
  # returns 'source of funding' for display to the applicant
  #
  # @param [FundingApplication] funding_application
  # @return [<Restforce::SObject] restforce_cash_contributions
  def salesforce_medium_cash_contributions(funding_application)

    client = SalesforceApiClient.new

    case_id = funding_application.salesforce_case_id

    restforce_cash_contributions =
      client.cash_contributions \
        (funding_application.salesforce_case_id)

  end

  # Used by cash_contribution controllers to direct the journey
  # based on values in answers_json
  #
  # Loops through cash_contributions stored in answers_json to see what
  # to update. If it finds an unfinished cash contribution it finds/creates
  # the cash contribution object, then redirects to a page
  # to enter updates for that cash contribution.
  # When all the cash contributions are marked as finished, redirects to
  # to the path for volunteers.
  #
  # 'record' in the iterator is an array containing the salesforce id
  # of the cash contribution at [0] and a hash at [1]
  #
  # @param [String] answers_json JSON string containing journey state
  def medium_cash_contribution_redirector(answers_json)

    client = ProgressUpdateSalesforceApiClient.new

    next_cash_contribution_id = nil

    answers_json['cash_contribution']['records']. each do |record|

      # record is an array containing a salesforce id at [0] nested hash.  
      # and a hash of data about the record at [1]
      if (record[1]['selected_for_update'] == 'true') && \
        (record[1]['update_finished'] == false)

        salesforce_income =
          client.get_medium_cash_contribution(record[0]).first

        cash_contribution = get_cash_contribution(record[0])

        # Not a bug. Salesforce stores amount expected in
        # Amount_you_have_received__c
        cash_contribution.amount_expected =
          salesforce_income.Amount_you_have_received__c

        cash_contribution.display_text =
          salesforce_income.Description_for_cash_contributions__c

        cash_contribution.save!

        # update this cash_contribution next, unless one chosen
        next_cash_contribution_id = cash_contribution.id unless \
          next_cash_contribution_id.present?

      end

    end

    # if we have found/built something redirect to that cc page
    if next_cash_contribution_id.present?

      redirect_to(
        funding_application_progress_and_spend_progress_update_cash_contribution_cash_contribution_now_path(
            progress_update_id:
              @funding_application.arrears_journey_tracker.progress_update.id,
            cash_contribution_id: next_cash_contribution_id

        )
      )

    else
      # All selected cash contributions have been addressed, go to volunteers page
      redirect_to(
        funding_application_progress_and_spend_progress_update_volunteer_volunteer_question_path(
            progress_update_id:
              @funding_application.arrears_journey_tracker.progress_update.id
        )
      )
    end

  end

  # Uses salesforce_project_income_id to retrieve an existing
  # CashContribution instance, if found.  Otherwise
  # Creates a new CashContribution instance.
  #
  # @param [String] salesforce_project_income_id Ref for a project_income
  #                                               record on salesforce
  # @return [ProjectUpdateCashContribution] 
  def get_cash_contribution(salesforce_project_income_id)

    cash_contribution = @funding_application.arrears_journey_tracker.\
      progress_update.progress_update_cash_contribution.find_by(
        salesforce_project_income_id: salesforce_project_income_id
      )

    if cash_contribution.nil?
      cash_contribution =
        @funding_application.arrears_journey_tracker.progress_update.\
          progress_update_cash_contribution.build

      cash_contribution.salesforce_project_income_id = \
        salesforce_project_income_id
    end

    cash_contribution

  end

  # Updates answers_json to indicate that a cash contribution
  # update has been completed.
  # 
  # @params [progress_update] answers_json Json containing journey answers
  # @params [String] salesforce_id Used to match against the jsonb key
  def set_cash_contribution_update_as_finished(progress_update, salesforce_id)

    progress_update.answers_json['cash_contribution']['records'][salesforce_id]['update_finished'] = true
    progress_update.save

  end

  # updates a given volunteer, affirms validation
  # and redirects to summary page if valid
  # or re-renders page to show validation errors
  #
  # @params [ProgressUpdateVolunteer] volunteer
  # @params [FundingApplication] funding_app
  def update_validate_redirect_volunteer(volunteer, funding_app)
    volunteer.update(params.require(:progress_update_volunteer).permit(
        :id,
        :description,
        :hours
      )
    )

    if @volunteer.valid?
      redirect_to(
        funding_application_progress_and_spend_progress_update_volunteer_volunteer_summary_path(
            progress_update_id:
              funding_app.arrears_journey_tracker.progress_update.id
        )
      )
    else
      render :show
    end
  end

  # Method to find the number of cash contributions for a project.
  #
  # @param [String] id A Project Id reference known to Salesforce
  # @return [Integer] count.  Number of cash contributions found
  def get_cash_contribution_count(salesforce_case_id)

    client = ProgressUpdateSalesforceApiClient.new

    count = client.cash_contribution_count(salesforce_case_id)

  end


  # updates a given non_cash_contribution, afirms validation
  # and redirects to summary page if valid
  # or re-renders page to show validation errors
  #
  # @params [ProgressUpdateNonCashContribution] non_cash_contribution
  # @params [FundingApplication] funding_app
  def update_validate_redirect_non_cash_contribution(non_cash_contribution, funding_app)
    non_cash_contribution.update(params.require(:progress_update_non_cash_contribution).permit(
        :id,
        :description,
        :value
      )
    )

    if non_cash_contribution.valid?
      redirect_to(
        funding_application_progress_and_spend_progress_update_non_cash_contribution_non_cash_contribution_summary_path(
            progress_update_id:
              funding_app.arrears_journey_tracker.progress_update.id
        )
      )
    else
      render :show
    end
  end

  # Method responsible for orchestrating the retrieval of
  # approved purposes from Salesforce
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  # @return [<Restforce::SObject] approved_purposes.
  #                      A Restforce collection with query results
  def salesforce_approved_purposes(funding_application)

    client = SalesforceApiClient.new

    case_id = funding_application.salesforce_case_id

    approved_purposes =
      client.project_approved_purposes \
        (funding_application.salesforce_case_id)

  end

  # Gets a hash of the outcome information from Salesforce
  #
  # The hash key forms the last part of the translation used,
  # So consider this if making a change.
  # For example, a key called 'improving_condition' will use
  # the translation at:
  # progress_and_spend.progress_update.outcome_type.improving_condition
  # on outcomes/show.html.erb
  #
  # @param [String] salesforce_case_id Salesforce ref for a Project
  # @return [Hash] outcomes_hash A hash populated with outcome information
  #                              that a user needs to complete.
  def get_outcomes_hash_from_salesforce(salesforce_case_id)

    outcomes_hash = {}

    client = ProgressUpdateSalesforceApiClient.new

    outcome_details = client.get_project_outcome_targets(salesforce_case_id)

    outcomes_hash[
      'improving_condition'
    ] = "" if outcome_details.Heritage_will_be_in_better_condition__c

    outcomes_hash[
      'explaining_heritage'
    ] = "" if outcome_details.Identified_and_better_explained__c

    outcomes_hash[
      'developing_skills'
    ] = "" if outcome_details.People_will_have_developed_skills__c

    outcomes_hash[
      'learning_heritage'
    ] = "" if outcome_details.People_will_have_learned_about_heritage__c

    outcomes_hash[
      'greater_wellbeing'
    ] = "" if outcome_details.People_will_have_greater_wellbeing__c

    outcomes_hash[
      'improving_resilience'
    ] = "" if outcome_details.The_organisation_will_be_more_resilient__c

    outcomes_hash[
      'making_better_place'
    ] = "" if outcome_details.A_better_place_to_live_work_or_visit__c

    outcomes_hash[
      'boosting_economy'
    ] = "" if outcome_details.The_local_economy_will_be_boosted__c

    outcomes_hash

  end

  # Builds a hash from the passed params.
  # Called from outcome/show.html.erb
  # Loops over recognised outcomes, looks for a matching param,
  # and adds a key value pair if found.
  # Hash then used to either store as JSON or re-render the form,
  # whichever is approriate.
  #
  # @param [String] salesforce_case_id Salesforce ref for a Project
  # @return [Hash] outcomes_hash A hash populated with outcome information
  #                              that a user needs to complete.
  def build_outcomes_hash_from_params(form_params)

    optional_outcome_types = [
      'improving_condition',
      'explaining_heritage',
      'developing_skills',
      'learning_heritage',
      'greater_wellbeing',
      'improving_resilience',
      'making_better_place',
      'boosting_economy'
    ]

    outcomes_hash = {}

    optional_outcome_types.each do |ot|

      outcomes_hash[ot] = form_params.fetch(ot) if form_params.has_key?(ot)

    end

    outcomes_hash

  end

  # Method responsible for orchestrating upload
  # of arrears data to Salesforce
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  # @param [CompletedArrearsJourney] CompletedArrearsJourney 
  #                                                 An instance of
  #                                                 CompletedArrearsJourney
  def upload_arrears_to_salesforce(funding_application, 
    completed_arrears_journey)

    salesforce_api_client = SalesforceApiClient.new
    form_id = salesforce_api_client.instantiate_arrears_form_type(
      funding_application, 
      completed_arrears_journey
    )

    progress_update_client = ProgressUpdateSalesforceApiClient.new
    upload_progress_update(
      progress_update_client, 
      funding_application, 
      form_id, 
      completed_arrears_journey
    ) if completed_arrears_journey.progress_update.present?

    payment_request_client = PaymentRequestSalesforceApiClient.new
    upload_payment_request(
      payment_request_client, 
      completed_arrears_journey, 
      form_id
    )  if completed_arrears_journey.payment_request.present?

    salesforce_api_client = SalesforceApiClient.new
    upload_bank_details(
      form_id,
      salesforce_api_client,
      payment_request_client,
      funding_application
    ) if completed_arrears_journey.payment_request
      .answers_json['bank_details_journey']['has_bank_details_update'] == "true"
     

    # set SF form id and updated at as time of upload 
    completed_arrears_journey.salesforce_form_id = form_id
    completed_arrears_journey.updated_at = DateTime.now()

    completed_arrears_journey.save
    
  end

  private

  # Method responsible for orchestrating upload
  # of progress update data to Salesforce
  #
  # @param [ProgressUpdateSalesforceApiClient] progress_update_salesforce_api 
  #                                                 An instance of
  #                                                 ProgressUpdateSalesforceApiClient
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  # @param [String] string salesfoce form id to upsert against
  #                                                  String
  # 
  # @param [CompletedArrearsJourney] CompletedArrearsJourney 
  #                                                 An instance of
  #                                                 CompletedArrearsJourney
  def upload_progress_update(client, funding_application, 
    form_id, completed_arrears_journey)

    progress_update = completed_arrears_journey
        .progress_update

    progress_update.answers_json.each do | field, flags |
      clear_unused_progress_update_data_items(
        field, 
        flags, 
        progress_update
      )
    end 

    client.upsert_project_update(funding_application, form_id, 
      completed_arrears_journey)

    upload_evidence_files(progress_update, form_id, client)

    # Upsert approved purposes if attached
    clear_approved_purposes_with_no_progress_update(progress_update)
    client.upsert_approved_purposes(progress_update, form_id)
    client.upsert_outcomes(funding_application, completed_arrears_journey)

    check_and_upload_digital_outputs(
      client,
      progress_update,
      completed_arrears_journey.id
    )

    check_and_upload_funding_acknowledgements(
      client,
      progress_update,
      form_id
    )

    progress_update.submitted_on = DateTime.now
    progress_update.save

  end

  # Method responsible for orchestrating upload
  # of progress update data to Salesforce
  #
  # @param [ProgressUpdateSalesforceApiClient] progress_update_salesforce_api 
  #                                                 An instance of
  #                                                 ProgressUpdateSalesforceApiClient
  # @param [CompletedArrearsJourney] completed_arrears_journey An instance of
  #                                                 CompletedArrearsJourney
  # @param [String] string salesfoce form id to upsert against
  #                                                  String
  def upload_payment_request(client, completed_arrears_journey, form_id)

    payment_request = completed_arrears_journey
      .payment_request

    client.upsert_payment_request(payment_request, form_id)

    payment_request.submitted_on = DateTime.now
    payment_request.save

  end

  # Method responsible for orchestrating upload
  # of bank details data to Salesforce
  #
  # @param [String] string salesforce form ID to upload against 
  #                                                 String
  # @param [SalesforceApiClient] salesforce_api_client An instance of
  #                                                 SalesforceApiClient
  # @param [PaymentRequestSalesforceApiClient] payment_request_client An instance of
  #                                                 PaymentRequestSalesforceApiClient
  # @param [FundingApplication] funding_application an instance of 
  #                                                  FundingApplication
  def upload_bank_details(form_id, salesforce_api_client, 
    payment_request_client, funding_application)

    # Find or create bank account in salesforce
    salesforce_bank_account_id = 
      salesforce_api_client.find_or_create_bank_account_details(funding_application)

    # Create link between form and account details with junction object
    salesforce_api_client.
      upsert_bank_account_payment_request_junction(
        salesforce_bank_account_id, 
        form_id
      )

    # Upload bank account evidence file
    payment_details = funding_application.payment_details

    payment_request_client.upsert_document_to_salesforce(
      payment_details.evidence_file.attachment,
      "Bank account evidence - #{payment_details.evidence_file_blob
        .filename}",
        salesforce_bank_account_id
    )
    
  end

  # Method responsible for deleting unused progress update data.
  #
  # Approved purposes and Outcomes Data types not targeted by this function:
  # 1. Approved purposes. Unused data is removed upon Save and Continue.
  # 2. Demographic. Mandatory question - answer always required
  # 3. Outcomes. Mandatory question - answer always required
  #
  # @param [field] field String value denoting field in answers JSON
  #
  # @param [flags] flags String Hash of flags denoting user answers to field
  #
  # @param [ProgressUpdate] progress_update An instance of
  #                                                 ProgressUpdate
  def clear_unused_progress_update_data_items(field, flags, progress_update)
    
    logger.info "Removing unused data from progress_update with id:" \
      "#{progress_update.id}"

    case field
    when 'risk'
      if flags['has_risk_update'] == true
        if flags['has_risk_register'] == 'true' 
         progress_update.progress_update_risk.destroy_all 
        elsif flags['has_risk_register'] == 'false' 
          progress_update.progress_update_risk_register.destroy_all
        end
      elsif flags['has_risk_update'] == false
        progress_update.progress_update_risk.destroy_all
        progress_update.progress_update_risk_register.destroy_all
      end
    when 'procurements'
      if flags['has_procured_goods'] == "true"
        if flags['has_procurement_report_evidence'] == 'true' 
          progress_update.progress_update_procurement.destroy_all 
        elsif flags['has_procurement_report_evidence'] == 'false' 
          progress_update.progress_update_procurement_evidence.destroy_all
        end
      elsif flags['has_procured_goods'] == "false"
        progress_update.progress_update_procurement.destroy_all  
        progress_update.progress_update_procurement_evidence.destroy_all
      end
    when 'events'
      progress_update.progress_update_event.destroy_all \
        if flags['has_upload_events'] == 'false'
    when 'photos'
      progress_update.progress_update_photo.destroy_all \
        if flags['has_upload_photos'] == 'false'
    when 'new_staff'
      progress_update.progress_update_new_staff.destroy_all \
        if flags['has_new_staff'] == 'false'
    when 'volunteer'
      progress_update.progress_update_volunteer.destroy_all \
        if flags['has_volunteer_update'] == false
    when 'new_expiry_date'
      progress_update.progress_update_new_expiry_date.destroy_all \
        if flags['date_correct'] == true
    when 'cash_contribution'
      progress_update.progress_update_cash_contribution.destroy_all \
        if flags['has_cash_contribution_update'] == false
    when 'non_cash_contribution'
      progress_update.progress_update_non_cash_contribution.destroy_all \
        if flags['has_non_cash_contribution'] == false
    when 'additional_grant_condition'
      progress_update.progress_update_additional_grant_condition.destroy_all \
        if flags['no_progress_update'] == true
    when 'statutory_permissions_licences'
      progress_update.progress_update_statutory_permissions_licence.destroy_all \
        if flags['has_statutory_permissions_licence'] == "false"
    end

  end

  # Method responsible for upserting any evidence files attached to 
  # project update (calls file uploader used in PtsSalesforceAPI
  # which could later be abstracted to more generic helper)
  #
  # @param [ProgressUpdate] progress_update An instance of
  #                                                 ProgressUpdate
  # @param [salesforce_project_update_id] Form Id of progress update
  #                                                  String
  # 
  # @param [ProgressUpdateSalesforceApiClient] progress_update_salesforce_api 
  #                                                 An instance of
  #                                                 ProgressUpdateSalesforceApiClient
  def upload_evidence_files(progress_update, salesforce_project_update_id, client)
    

    unless progress_update.progress_update_photo.empty?
      progress_update.progress_update_photo.each do | photo |
        client.upsert_document_to_salesforce(
          photo.progress_updates_photo_files.attachment, 
          "Photo evidence - #{photo
            .progress_updates_photo_files_blob
              .filename}",
          salesforce_project_update_id
        )
      end
    end

    unless progress_update.progress_update_event.empty?
      progress_update.progress_update_event.each do | event |
        client.upsert_document_to_salesforce(
          event.progress_updates_event_files.attachment, 
          "Event evidence - #{event
            .progress_updates_event_files_blob
              .filename}",
          salesforce_project_update_id
        )
      end
    end

    unless progress_update.progress_update_new_staff.empty?
      progress_update.progress_update_new_staff.each do | new_staff |
        client.upsert_document_to_salesforce(
          new_staff.progress_updates_new_staff_files.attachment, 
          "New staff evidence - #{new_staff
            .progress_updates_new_staff_files_blob
              .filename}",
          salesforce_project_update_id
        )
      end
    end

    unless progress_update.progress_update_procurement_evidence.empty?
      progress_update.progress_update_procurement_evidence.each do 
        | procurement_evidence |
        client.upsert_document_to_salesforce(
          procurement_evidence
            .progress_update_procurement_evidence_file
              .attachment, 
          "Procurement evidence - #{procurement_evidence
            .progress_update_procurement_evidence_file_blob
              .filename}",
          salesforce_project_update_id
        )
      end
    end

    unless progress_update.progress_update_statutory_permissions_licence.empty?
      progress_update.progress_update_statutory_permissions_licence.each do 
        | statutory_permissions_licence |
        client.upsert_document_to_salesforce(
          statutory_permissions_licence
            .progress_update_statutory_permissions_licence_file
              .attachment, 
          "Statutory permission & licence evidence - #{statutory_permissions_licence
            .progress_update_statutory_permissions_licence_file_blob
              .filename}",
          salesforce_project_update_id
        )
      end
    end

    unless progress_update.progress_update_risk_register.empty?
      progress_update.progress_update_risk_register.each do | risk_register |
        client.upsert_document_to_salesforce(
          risk_register.progress_update_risk_register_file.attachment, 
          "Risk register evidence - #{risk_register
            .progress_update_risk_register_file_blob
              .filename}",
          salesforce_project_update_id
        )
      end
    end
  end
    
  # return the spend amount that results in the need to capture spending evidence.
  # This value is different for 100-250k applications and those over 250k.
  # Makes a call to Salesforce under the hood.
  # 
  # @params [FundingApplication] funding_application
  # @return [Integer] spend_amount The threshold spend amount
  def get_spend_threshold(funding_application)
    set_award_type(funding_application)
    spend_amount = 500 if @funding_application.is_100_to_250k?
    # Large to follow - development spend threshold could be less than £500
  end

  # Redirects the spend journey depending on the user's answers
  # Will update with the appropriate journey status when redirecting
  #
  # @param [String] answers_json JSON string containing payment details
  #                              journey state
  # @param [Boolean] use_high_spend_summary Optional param supplied by 
  #                  calling function.  True if skipping to high spend summary
  # @param [Boolean] use_low_spend_summary Optional param supplied by
  #                  calling function.  True if skipping low spend summary
  def spend_journey_redirector(answers_json, use_high_spend_summary = false,
      use_low_spend_summary = false)

    to_do_array = answers_json['arrears_journey']['spend_journeys_to_do']

    if to_do_array.empty?

      set_arrears_payment_status(JOURNEY_STATUS[:completed])

      redirect_to \
        funding_application_progress_and_spend_progress_and_spend_tasks_path()

    else

      # Lookup first item in array, and redirect there
      if to_do_array.first.has_key?("spends_over")

        set_arrears_payment_status(JOURNEY_STATUS[:in_progress])

        if use_high_spend_summary
          redirect_to \
            funding_application_progress_and_spend_payments_high_spend_summary_path()
        else
          redirect_to \
            funding_application_progress_and_spend_payments_high_spend_add_path()
        end

      elsif to_do_array.first.has_key?("spends_under")

        set_arrears_payment_status(JOURNEY_STATUS[:in_progress])

        if use_low_spend_summary
          redirect_to \
            funding_application_progress_and_spend_payments_low_spend_summary_path()
        else
          redirect_to \
            funding_application_progress_and_spend_payments_low_spend_select_path()
        end

      end

    end

  end

  # Updates the status for a payment request when part of the
  # arrears payment journey.
  # Find the in progress payment request through the arrears tracker
  # Then updates its answers_json withe the status param
  #
  # @param [Integer] status_integer See Enums::ArrearsJourneyStatus
  def set_arrears_payment_status(status_integer)

    payment_request = @funding_application.arrears_journey_tracker.payment_request

    logger.info("Setting arrears status to "\
      "#{journey_status_string(status_integer)} for "\
        "payment_request.id #{payment_request.id}")

    payment_request.answers_json['arrears_journey']['status'] = status_integer
    payment_request.save!

  end

  # Removes first item in to do array, so that it will not be revisited
  # unless selected by the user again.
  #
  # If applicants use the browser arrows to drive the journey backwards and
  # forward, then JSON in the spend journey can become invalid.
  # To avoid showing a user a rails error, log and redirect the user back to
  # the spend-so-far page, which is a safe place to return to any aspect of
  # the spend journey.
  #
  # @param [PaymentRequest] payment_request
  def remove_spend_journey_from_todo_array(payment_request)

    begin

      payment_request.\
        answers_json['arrears_journey']['spend_journeys_to_do'].shift
      payment_request.save!

    rescue

      Rails.logger.info("Exception in remove_spend_journey_from_todo_array " \
        "for funding application #{@funding_application.id}. Redirecting to " \
          "spend-so-far path.")

      redirect_to \
        funding_application_progress_and_spend_payments_spend_so_far_path()

    end

  end

  # Retrieves cost headings from Salesforce
  # Only suited for for medium application < 250001 at the moment
  #
  # @param [FundingApplication] funding_application
  # @return [<Restforce::SObject] restforce_cash_contributions
  def get_salesforce_cost_headings(funding_application)

    client = PaymentRequestSalesforceApiClient.new

    set_award_type(funding_application)

    record_type_id = client.record_type_id_medium_grant_cost \
      if funding_application.is_100_to_250k?

    # large arrears payments will need own function

    case_id = funding_application.salesforce_case_id

    restforce_cash_contributions =
      client.salesforce_cost_headings(
        case_id, 
        record_type_id
      )

  end

  # Used for Low spend journey only.
  # Uses spend_threshold stored in JSON
  # Saves repeated calls to Salesforce
  #
  # Testing has shown that using the JSON can break if a user goes
  # backwards and forwards a lot using the browser.
  # Handle all exceptions by making the expensive call to Salesforce.
  #
  # @param [PaymentRequest] payment_request PaymentRequest instance that
  #                                         the array is recorded against
  # @param [FundingApplication] funding_application
  # @return [Integer] spend_threshold The spend level for this spend journey
  def get_low_spend_threshold_from_json(payment_request, funding_application)

    begin

      # The first journey in [spend_journeys_to_do],
      # will always be the journey we are in.
      payment_request.answers_json['arrears_journey']['spend_journeys_to_do'].\
        first['spends_under']['spend_threshold']

    rescue Exception => e

      Rails.logger.error(
        "Could not get low spend threshold for payment_request.id: " \
          "#{payment_request.id} from JSON because error occurred: " \
            "#{e.message}. Retreiving from Salesforce instead.")

      get_spend_threshold(funding_application)

    end

  end

  # Used for High spend journey only.
  # Uses spend_threshold stored in JSON
  # Saves repeated calls to Salesforce
  #
  # Testing has shown that using the JSON can break if a user goes
  # backwards and forwards a lot using the browser.
  # Handle all exceptions by making the expensive call to Salesforce.
  #
  # @param [PaymentRequest] payment_request PaymentRequest instance that
  #                                         the array is recorded against
  # @param [FundingApplication] funding_application
  # @return [Integer] spend_threshold The spend level for this spend journey
  def get_high_spend_threshold_from_json(payment_request, funding_application)

    begin
      # The first journey in [spend_journeys_to_do],
      # will always be the journey we are in.
      payment_request.answers_json['arrears_journey']['spend_journeys_to_do'].\
        first['spends_over']['spend_threshold']

    rescue Exception => e

      Rails.logger.error(
        "Could not get high spend threshold for payment_request.id: " \
          "#{payment_request.id} from JSON because error occurred: " \
            "#{e.message}. Retreiving from Salesforce instead.")
      unless funding_application.nil?

        get_spend_threshold(funding_application)

      else

        0 # High spend validation passes nil funding_application, for err msg

      end

    end

  end

  # Retrieves the cost headings used by an applicant when they applied
  # These are the cost headings that can be used to record items of spend.
  #
  # Tries to gets cached headings from answers_json if they are there.
  # Otherwise gets the headings from Salesforce and updates answers_json.
  # 
  # @param [FundingApplication] funding_application
  # @return [Array] headings An array of cost headings
  def get_headings(funding_application)

    payment_request =
      funding_application.arrears_journey_tracker.payment_request

    # The first journey in [spend_journeys_to_do],
    # will always be the journey we are in.
    begin
      headings = 
        payment_request.answers_json['arrears_journey']['spend_journeys_to_do'].\
          first['spends_over']['cost_headings']
    rescue
      headings = []
    end

    if headings.empty?

      headings = get_salesforce_cost_headings(
        @funding_application
      )
  
      update_high_spend_headings_list(
        headings,
        payment_request
      )
    
    end

    headings

  end

  # Add and Edit controllers for high spends share a lot of code in their
  # update method.  This consolidates into one function.
  #
  # Sets variables for validation and rendering :show
  # Updates HighSpend
  # Redirects if valid.
  #
  # @param [HighSpend] high_spend
  # @param [PaymentRequest] payment_request
  # @param [FundingApplication] funding_application
  def high_spend_add_edit_controller_update_helper(high_spend,
    payment_request, funding_application, params)

    @spend_threshold = get_high_spend_threshold_from_json(
      payment_request,
      funding_application
    )

    high_spend.spend_threshold = @spend_threshold

    @headings = get_headings(funding_application)
    high_spend.cost_headings = @headings

    high_spend.validate_save_continue = true

    high_spend.update(fetched_high_spend_params(params))

    unless high_spend.errors.any?

      high_spend.date_of_spend = DateTime.new(
        high_spend.date_year.to_i, 
        high_spend.date_month.to_i, 
        high_spend.date_day.to_i 
      )

      high_spend.save!

      redirect_to(
        funding_application_progress_and_spend_payments_high_spend_evidence_path(
        high_spend_id: high_spend.id
        )
      )

    else

      render :show

    end

  end


  # Updates answers_json to store headings for high spends, so the the 
  # slow Salesforce call only happens once,
  #
  # If applicants use the browser arrows to drive the journey backwards and
  # forward, then JSON in the spend journey can become invalid.
  # To avoid showing a user a rails error, log and redirect the user back to
  # the spend-so-far page, which is a safe place to return to any aspect of
  # the spend journey.
  #
  # @param [Array] headings An array of cost headings
  # @param [PaymentRequest] payment_request PaymentRequest instance that
  #                                         the array is recorded against
  def update_high_spend_headings_list(headings, payment_request)

    begin

      # The first journey in [spend_journeys_to_do],
      # will always be the journey we are in.
      payment_request.answers_json['arrears_journey']['spend_journeys_to_do'].\
        first['spends_over']['cost_headings'] = headings

      payment_request.save!

    rescue

      Rails.logger.info("Exception in update_high_spend_headings_list for " \
        "funding application #{@funding_application.id}. Redirecting to " \
          "spend-so-far path.")

      redirect_to \
        funding_application_progress_and_spend_payments_spend_so_far_path()

    end

  end

  def fetched_high_spend_params(params)
    params.fetch(:high_spend, {}).permit(
      :evidence_of_spend_file,
      :cost_heading, :description,
      :date_day,
      :date_month,
      :date_year,
      :amount,
      :vat_amount
    )
  end

  # Allows returning applicants to see the date they added first time
  # when adding a high spend.
  # Breaks a datetime into its parts.
  #
  # @param [ProgressUpdateCashContribution] cash_contribution
  def populate_day_month_year(high_spend)

    date_of_spend = high_spend&.date_of_spend

    if date_of_spend.present?
      high_spend.date_day = date_of_spend.day
      high_spend.date_month = date_of_spend.month
      high_spend.date_year = date_of_spend.year
    end

  end

  # If a user has left the high spend journey without attaching
  # a file,then delete those spends.
  #
  # Before showing the form, it needs to reload payment details
  # from the database, so that :show doesn't show the cached,
  # deleted items.
  #
  # This is an MVP approach. Team would prefer a different approach
  # where we showed the files attached on the high spend summary screen, and
  # validated that each spend had a file before proceeding.
  # The submit function should have similar validation to prevent URL
  # hacking.
  #
  # @param [PaymentRequest] payment_request
  def remove_high_spends_with_no_file(payment_request)

    payment_request.high_spend.each do |high_spend|

      unless high_spend.evidence_of_spend_file.present?
        high_spend.destroy
      end

    end

    payment_request.high_spend.reload

  end

  # Users that go backwards and forwards with their browser, or leave the
  # journey on the approved purposes page, could have approved purpose
  # objects stored with no progress update.
  # This function clears those out.  Used when showing the outcomes summary
  # page so that the pages shows correctly if refreshed.
  # Used when submitting, so empty outcomes objects no created
  # @param [ProgressUpdate] progress_update 
  def clear_approved_purposes_with_no_progress_update(progress_update)
    
    progress_update.progress_update_approved_purpose.each do |ap|
      ap.destroy_all unless ap.progress.present?
    end

  end

  # Returns object if user answered yes to has digital outputs question.
  # Handle parsing error silently, so journey not impacted,
  # Sentry errors will be raised in the event of an error, as the
  # JSON should always be correctly format at the point this is called
  # Which is on summary pages.
  # @params [ProgressUpdate] progress_update
  # @return [ProgressUpdateDigitalOutput] result Provided if digital 
  #                                        output question answered with yes
  def get_digital_output_if_required(progress_update)

    result = nil

    begin

      user_said_yes = 
        progress_update.\
          answers_json['digital_outputs']['has_digital_outputs'] == "true"

      user_said_yes ? \
        result = progress_update&.progress_update_digital_output&.first : nil

    rescue => e
      Rails.logger.error(e.message)
      result
    end

  end

  # True if user has provided a bank account before.
  # @param [FundingApplication] funding_application
  # @return [Boolean] org_has_bank_account_in_salesforce True if so
  #
  def ask_if_bank_account_changed?(funding_application)

    client = PaymentRequestSalesforceApiClient.new

    client.org_has_bank_account_in_salesforce(
      funding_application.organisation.salesforce_account_id
    )

  end

  # upsert digital outputs - if user answered Yes to question, which
  # is stored as has_digital_outputs == "true"
  #
  # @param [ProgressUpdateSalesforceApiClient] client Reusing SF client object
  # @param [ProgressUpdate] progress_update Contains any digital outputs
  # @param [String] completed_journey_id External reference for
  #                                                  completed_arrears_journey
  def check_and_upload_digital_outputs(client, progress_update, completed_journey_id)
    
    progress_update.has_digital_outputs = \
      progress_update.answers_json['digital_outputs']\
        ['has_digital_outputs'] if \
          progress_update.answers_json.has_key?('digital_outputs')

    client.upsert_digital_outputs(
      completed_journey_id,
      progress_update.progress_update_digital_output.first.description
    ) if progress_update.has_digital_outputs == "true"

  end

  # upsert funding acknowledgements - unless user answered 
  # "I do not have an update yet"
  #
  # Controls the loop here and calls the upsert function for each item.
  # This means the client API's retry only occurs on a problem item 
  # which is faster than retrying all items.
  #
  # concatenates object.id and ack_type to make an external_id for SF
  #
  # @param [ProgressUpdateSalesforceApiClient] client Reusing SF client object
  # @param [ProgressUpdate] progress_update To get any funding_acknowledgments
  # @param [String] form_id Salesforce reference for its relevant Form__c instance
  #
  def check_and_upload_funding_acknowledgements(client, progress_update, form_id)

    ack_object = progress_update&.progress_update_funding_acknowledgement&.first

    acks_json = ack_object&.acknowledgements

    unless acks_json.nil? || acks_json['no_update']['selected'] == 'true'

      acks_json.each do |ack_type, ack_desc|

        client.upsert_funding_acknowledgement(
          progress_update.progress_update_funding_acknowledgement.first.id + ack_type,
          form_id,
          ack_object.get_salesforce_funding_acknowledgement_type(ack_type),
          ack_desc['acknowledgement']
        ) unless ack_type == 'no_update'

      end

    end

  end

  # Calculates the amount The Fund will pay when an arrears payment request
  # is made
  # @param [CompletedArrearsJourney] completed_arrears_journey Tracker
  #                                 object for completed arrears journeys
  # @param [payment_percentage] payment_percentage The percentage of the total
  #                             spend that we will pay for.
  # @return [Float] result of multiplying total spend by payment percentage / 100
  def get_arrears_payment_amount(completed_arrears_journey, payment_percentage)

    get_total_spend(completed_arrears_journey) * (payment_percentage / 100)

  end

  # Gets the total spend recorded by a grantee in the arrears journey
  # @param [CompletedArrearsJourney] completed_arrears_journey Tracker
  #                                 object for completed arrears journeys
  # @return [Float] total_spend Sum of high and low spends
  def get_total_spend(completed_arrears_journey)

    total_spend = 0

    if completed_arrears_journey.payment_request.present?

      high_spend =
        completed_arrears_journey.payment_request.high_spend.sum {|hs| hs.amount + hs.vat_amount}

      low_spend =
        completed_arrears_journey.payment_request.low_spend.sum {|ls| ls.total_amount + ls.vat_amount}

      total_spend = high_spend + low_spend
    
    end

    total_spend

  end

end
