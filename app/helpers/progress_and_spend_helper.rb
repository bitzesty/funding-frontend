module ProgressAndSpendHelper
  include SalesforceApi
  include ProgressUpdateSalesforceApi
  include FundingApplicationHelper
  include Enums::ArrearsJourneyStatus

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
  # @params [FundingAppplication] funding_app
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
  # @params [FundingAppplication] funding_app
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
  # of progress update data to Salesforce
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  def upload_progress_update(funding_application)

    client = ProgressUpdateSalesforceApiClient.new

    progress_update = funding_application.arrears_journey_tracker.progress_update

    progress_update.answers_json.each do | field, flags |
      clear_unused_progress_update_data_items(
        field, 
        flags, 
        progress_update
      )
    end 

    progress_update = funding_application
      .arrears_journey_tracker
        .progress_update

      salesforce_project_update_id = client.upsert_project_update(
        funding_application
      )

    upload_evidence_files(progress_update, salesforce_project_update_id, client)

    # Upsert approved purposes if attached
    client.upsert_approved_purposes(progress_update, salesforce_project_update_id)
    client.upsert_outcomes(funding_application)

  end
  
  private

  # Method responsible for deleting unused progress update data.
  #
  # Approved purposes and Outcomes Data types not targeted by this function:
  # 1. Approved purposes. Unused data is removed upon Save and Continue.
  # 2. Demographic. Mandatory question - answer always required
  # 3. Outcomes. Mandatory question - answer always required
  #
  # @param [field] field String value denoting field in answers JSON
  #
  # @param [flags] flags String Hash of flags denoting user answers to feild
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
  # which could later be abstarcted to more generic helper)
  #
  # @param [ProgressUpdate] progress_update An instance of
  #                                                 ProgressUpdate
  # @param [salesforce_project_update_id] Form Id of progress update
  #                                                  String
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
  # 
  # @params [FundingApplication] funding_application
  # @return [Integer] spend_amount The threshold spend amount
  def get_spend_threshold(funding_application)
    set_award_type(funding_application)
    spend_amount = 250 if @funding_application.is_100_to_250k?
    # Large to follow
  end

  # Redirects the spend journey depending on the user's answers
  # Will update with the appropriate journey status when redirecting
  #
  # @param [String] answers_json JSON string containing payment details
  #                              journey state
  def spend_journey_redirector(answers_json)

    to_do_array = answers_json['arrears_journey']['spend_journeys_to_do']

    if to_do_array.empty?

      set_arrears_payment_status(JOURNEY_STATUS[:completed])

      redirect_to \
        funding_application_progress_and_spend_progress_and_spend_tasks_path()

    else

      # Check first item in array, and redirect there
      if to_do_array[0].has_key?("spends_over")

        set_arrears_payment_status(JOURNEY_STATUS[:in_progress])
        render :show # todo: redirect to big spend

      elsif to_do_array[0].has_key?("spends_under")

        set_arrears_payment_status(JOURNEY_STATUS[:in_progress])
        render :show # todo: redirect to little spend

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

end
