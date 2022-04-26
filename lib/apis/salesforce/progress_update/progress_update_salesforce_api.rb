module ProgressUpdateSalesforceApi

  # Class to allow interaction with Salesforce via a Restforce client
  class ProgressUpdateSalesforceApiClient
    include SalesforceApiHelper

    # Overrides the .new() method, allowing us to initialise a Restforce client
    # when the class is instantiated
    def initialize

      initialise_client

    end
   
    # Method to find a cash contribution by id.
    #
    # @param [String] id An Id reference known to Salesforce
    # @return [<Restforce::SObject] restforce_response.  A Restforce collection
    #                                     with query results
    def get_medium_cash_contribution(salesforce_project_income_id)
      Rails.logger.info("Retrieving cash contribution aka project income" \
        "for Id: #{salesforce_project_income_id}")

      restforce_response = []

      query_string = "SELECT " \
        "Description_for_cash_contributions__c, Amount_you_have_received__c " \
          "FROM Project_Income__c " \
            "where Id = '#{salesforce_project_income_id}' " \
              "and recordType.DeveloperName = 'Delivery' "

      restforce_response = run_salesforce_query(query_string, 
        "get_medium_cash_contribution", salesforce_project_income_id) \
          if query_string.present?

      restforce_response

    end

    # Method to find the number of cash contributions for a project.
    #
    # @param [String] id A Project Id reference known to Salesforce
    # @return [Integer] restforce_response.size.  Number found
    def cash_contribution_count(salesforce_case_id)
      Rails.logger.info("Retrieving cash contribution count" \
        "for Case Id: #{salesforce_case_id}")

      restforce_response = []

      query_string = "SELECT COUNT() from Project_Income__c " \
        "where Case__c = '#{salesforce_case_id}'"

      restforce_response = run_salesforce_query(query_string, 
        "cash_contribution_count", salesforce_case_id) \
          if query_string.present?

      restforce_response.size

    end

    # Gets the outcomes that an applicant indicated their project would
    # address when they applied.
    #
    # @param [String] id A Project Id reference known to Salesforce
    # @return [<Restforce::SObject>] restforce_response&first.
    #                   First row in response containing query results needed
    def get_project_outcome_targets(salesforce_case_id)
      Rails.logger.info("Retrieving outcome details for" \
        "for Case Id: #{salesforce_case_id}")

      restforce_response = []

      query_string = "SELECT " \
        "Heritage_will_be_in_better_condition__c, " \
        "Identified_and_better_explained__c, " \
        "People_will_have_developed_skills__c, " \
        "People_will_have_learned_about_heritage__c, " \
        "People_will_have_greater_wellbeing__c, " \
        "The_organisation_will_be_more_resilient__c, " \
        "A_better_place_to_live_work_or_visit__c, " \
        "The_local_economy_will_be_boosted__c " \
        "FROM Case " \
        "where Id = '#{salesforce_case_id}'"

      restforce_response = run_salesforce_query(query_string,
        "get_outcome_details", salesforce_case_id) \
          if query_string.present?

      restforce_response.first

    end

    # Method to upsert a PTS form files in Salesforce for a Permission to Start application
    #
    # @param [ActiveStorageBlob] file attachment to upload
    # @param [String] type The type of file to upload (e.g. 'photo evidence')
    # @param [String] salesforce_reference The Salesforce Form reference
    #                                              to link this upload to
    # @param [String] description A description of the file being uploaded
    def upsert_document_to_salesforce(
      file,
      type,
      salesforce_reference,
      description = nil
    )

      Rails.logger.info("Creating #{type} file in Salesforce")

      UploadDocumentJob.perform_later(
        file,
        type,
        salesforce_reference,
        description
      )

      Rails.logger.info("Finished creating #{type} file in Salesforce")

    end

    # Method responsible for upserting any progress update data models
    # to their counter parts in SF
    #
    # @param [FundingApplication] funding_application An instance of
    #                                                 FundingApplication
    #
    def upsert_project_update(funding_application)

      retry_number = 0

      progress_update = funding_application.arrears_journey_tracker.progress_update

      Rails.logger.info("Upserting progress update data " \
        "to progress update with ID: #{progress_update.id}")

      begin

        # Instantiates our form 
        salesforce_project_update_id = @client.upsert!(
          'Forms__c',
          'Frontend_External_Id__c',
          Case__c: funding_application.salesforce_case_id,
          Frontend_External_Id__c: progress_update.id,
          RecordTypeId: get_salesforce_record_type_id('Project_Update', 'Forms__c')
        )

        # Attach risks to form 
        progress_update.progress_update_risk.each do | risk | 
          @client.upsert!(
            'Update_Risk__c',
            'External_Id__c',
            External_Id__c: risk.id,
            Form__c: salesforce_project_update_id,
            Impact__c: translate_risk_picklist_for_salesforce(risk.impact), 
            Is_this_still_a_risk__c: risk.is_still_risk,
            Explain_the_risk_identified__c: risk.description,
            Likelihood__c: translate_risk_picklist_for_salesforce(risk.likelihood),
            Risk_Mitigation__c: risk.is_still_risk_description
          )
        end

        # Attach volunteers to form 
        progress_update.progress_update_volunteer.each do | volunteer | 
          @client.upsert!(
            'Update_volunteer_contribution__c',
            'External_Id__c',
            External_Id__c: volunteer.id,
            Form__c: salesforce_project_update_id,
            Total_hours_spent_on_this_task__c: volunteer.hours,
            Description__c: volunteer.description,
          )
        end

        # Attach CC to form 
        progress_update.progress_update_cash_contribution.each do 
          | cash_contribution | 
          @client.upsert!(
            'Update_Cash_Contribution__c',
            'External_Id__c',
            External_Id__c: cash_contribution.id,
            Form__c: salesforce_project_update_id,
            Amount_expected__c: cash_contribution.amount_expected,
            Amount_received_so_far__c: cash_contribution.amount_received_so_far, 
            Description__c: cash_contribution.display_text,
            Explain_why_you_will_not_receive_total__c: cash_contribution
              .reason_amount_expected_not_received, 
            Have_you_received_the_total_amount__c: cash_contribution
              .received_amount_expected.present? ?  
                cash_contribution.received_amount_expected : false , 
            Will_you_receive_the_total_amount__c: cash_contribution
              .will_receive_amount_expected.present? ? 
                cash_contribution.will_receive_amount_expected : false,  
            # Will need to upload source of funding for large
            # Source_of_funding__c: cash_contribution. 
            When_do_you_expect_to_receive_the_total__c: cash_contribution
              .date_amount_received&.strftime("%Y-%m-%d"),
          )
        end

        # Attach non-CC to form 
        progress_update.progress_update_non_cash_contribution.each do 
          | non_cash_contribution | 
          @client.upsert!(
            'Update_Non_Cash_Contribution__c',
            'External_Id__c',
            External_Id__c: non_cash_contribution.id,
            Form__c: salesforce_project_update_id,
            Value_of_secured_non_cash_contribution__c: 
              non_cash_contribution.value, 
            Description__c: non_cash_contribution.description,
          )
       end

        # Attach procurements to form 
        progress_update.progress_update_procurement.each do | procurement | 
          @client.upsert!(
            'Update_Procurement__c',
            'External_Id__c',
            External_Id__c: procurement.id,
            Form__c: salesforce_project_update_id,
            Amount__c: procurement.amount , 
            Brief_description_of_item_or_service__c: procurement.description,
            Date_of_purchase_or_contract_award_date__c: 
              procurement.date&.strftime("%Y-%m-%d"),
            Supplier_contractor_or_consultant__c: procurement.name,
            Value_for_money_of_winning_supplier__c:
              procurement.supplier_justification, 
            Was_this_the_lowest_tender__c: procurement.lowest_tender
          )
        end

        # Upsert new project completion date if provided
        unless progress_update.progress_update_new_expiry_date.empty?
          @client.upsert!(
            'Forms__c',
            'Frontend_External_Id__c',
            Case__c: funding_application.salesforce_case_id,
            Frontend_External_Id__c: progress_update.id,
            New_proposed_grant_expiry_date__c: progress_update
              .progress_update_new_expiry_date
                .first.full_date.strftime("%Y-%m-%d"),
            Briefly_explain_why_you_need_more_time__c: progress_update
              .progress_update_new_expiry_date
                .first.description,
            Do_you_still_expect_to_complete_by_GED__c: false
          )
        else
          @client.upsert!(
            'Forms__c',
            'Frontend_External_Id__c',
            Case__c: funding_application.salesforce_case_id,
            Frontend_External_Id__c: progress_update.id,
            Do_you_still_expect_to_complete_by_GED__c: true
          )
        end

        Rails.logger.info("Successfuly upserted progress update data with " \
          "ID: #{progress_update.id}")

        return salesforce_project_update_id

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.error(
            "Error upserting progress update with ID: #{progress_update.id}"
          )

          sleep(rand(0..max_sleep_seconds))

        else
          # Raise and allow global exception handler to catch
          raise
        end

      end

    end

    # Method responsible for upserting any approved purpose models
    # to SF
    #
    # @param [ProgressUpdate] progress_update An instance of
    #                                                 ProgressUpdate
    # 
    # @param [int] form_id Form ID to upsert against
    #                    
    def upsert_approved_purposes(progress_update, form_id)

      retry_number = 0

      begin

        Rails.logger.info("Upserting approved purposes to " \
          "progress update with ID: #{progress_update.id}")

        # Attach approved purposes
        progress_update.progress_update_approved_purpose.each do
          | approved_purpose | 
          @client.upsert!(
            'Update_approved_purpose__c',
            'External_Id__c',
            External_Id__c: approved_purpose.id,
            Approved_Purpose__c: approved_purpose.description,
            Form__c: form_id,
            Update__c: approved_purpose.progress,
          )

          Rails.logger.info("Successfuly upserted progress update " \
            "approved purpose with ID: #{approved_purpose.id}")

        end

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.error(
            "Error upserting appproved purpose to progress update" \
              "with ID: #{progress_update.id}"
          )

          sleep(rand(0..max_sleep_seconds))

        else
          # Raise and allow global exception handler to catch
          raise
        end

      end

    end



    # Method responsible for upserting any outcome models
    # to SF counterparts
    #
    # @param [FundingApplication] funding_application An instance of
    #                                                 FundingApplication
    #    
    def upsert_outcomes(funding_application)
      retry_number = 0

      begin

        progress_update = funding_application.arrears_journey_tracker.progress_update

        progress_update_id = progress_update.id
        case_id = funding_application.salesforce_case_id

        Rails.logger.info("Upserting outcomes to " \
          "progress update with ID: #{progress_update_id}")

        # Upsert new project completion date if provided
        unless progress_update.progress_update_demographic.empty?
          @client.upsert!(
            'Forms__c',
            'Frontend_External_Id__c',
            Case__c: funding_application.salesforce_case_id,
            Frontend_External_Id__c: progress_update_id,
            A_wider_range_of_people_will_be_involved__c: progress_update
              .progress_update_demographic.first.explanation
          )
        end

        unless progress_update.progress_update_outcome.empty?
          progress_update.progress_update_outcome.first.progress_updates
            .each do | outcome, update | 
            case outcome
            when 'boosting_economy'
             upsert_outcomes_field(progress_update_id, 
              'The_local_economy_will_be_boosted__c', 
                update, case_id)
            when 'developing_skills'
             upsert_outcomes_field(progress_update_id, 
              'People_will_have_developed_skills__c', 
                update, case_id)
            when 'greater_wellbeing'
             upsert_outcomes_field(progress_update_id, 
              'People_will_have_greater_wellbeing__c', 
                update, case_id)
            when 'learning_heritage'
             upsert_outcomes_field(progress_update_id, 
              'People_will_have_learned_about_heritage__c', 
                update, case_id)
            when 'explaining_heritage'
             upsert_outcomes_field(progress_update_id, 
              'Identified_and_better_explained__c', 
                update, case_id)
            when 'improving_condition'
             upsert_outcomes_field(progress_update_id, 
              'Heritage_will_be_in_better_condition__c', 
                update, case_id)
            when 'making_better_place'
             upsert_outcomes_field(progress_update_id, 
              'A_better_place_to_live_work_or_visit__c', 
                update, case_id)
            when 'improving_resilience'
             upsert_outcomes_field(progress_update_id, 
              'The_organisation_will_be_more_resilient__c', 
                update, case_id)
            end

            Rails.logger.info("Successfuly upserted #{outcome} outcome " \
              "to progress update with ID: #{progress_update_id}")

          end
        end

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.error(
            "Error upserting outcomes to progress update " \
              "with ID: #{progress_update.id}"
          )

          sleep(rand(0..max_sleep_seconds))

        else
          # Raise and allow global exception handler to catch
          raise
        end

      end
    end

    private

    # Runs upsert with paramatised outcome field to update
    # 
    # @param [progress_update_id] Int progress_update_id to upsert against
    # @param [salesforce_field] String Name of SF feild to update
    # @param [update] String Value of feild being updated
    # @param [case_id] Int case id of form being updated
    # 
    def upsert_outcomes_field(progress_update_id, salesforce_field, update, case_id)
      @client.upsert!(
        'Forms__c',
        'Frontend_External_Id__c',
        Case__c: case_id,
        Frontend_External_Id__c: progress_update_id,
        salesforce_field.to_sym => update
      )
    end

    def translate_risk_picklist_for_salesforce(selection_index)
      case selection_index
      when 3 
        return 'low'
      when 2
        return 'medium'
      when 1
        return 'high'
      end
    end

  end

end

