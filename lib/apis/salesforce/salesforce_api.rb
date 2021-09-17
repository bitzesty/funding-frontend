  module SalesforceApi

  # Class to allow interaction with Salesforce via a Restforce client
  class SalesforceApiClient

    include ApplicationHelper

    MAX_RETRIES = 3

    # Overrides the .new() method, allowing us to initialise a Restforce client
    # when the SalesforceApiClient class is instantiated
    def initialize

      initialise_client

    end

    # Method to retrieve details needed during a payment request journey
    #
    # @example
    #
    #   instantiated_object.get_payment_related_details('6665bd00-db85-4f68-95e3-16f9ca99ba40')
    #
    # @param [String] id A project's UUID
    #
    # @return [Hash] A Hash, currently containing only the amount awarded to the project
    #                and the percentage of the total costs that the organisation have agreed
    #                to award
    def get_payment_related_details(id)

      Rails.logger.info("Retrieving payment-related details for project ID: #{id}")

      retry_number = 0

      begin

        # Equivalent of "SELECT Grant_Award__c, Grant_Percentage__c FROM Case WHERE ApplicationId__c = '#{id}'"
        restforce_response = @client.select('Case', id, ['Grant_Award__c', 'Grant_Percentage__c'], 'ApplicationId__c')

      rescue Restforce::NotFoundError => e

        Rails.logger.error(
          "Exception occured when retrieving payment-related details for project ID: #{id}:" \
          " - no Case found for #{id} (#{e})"
        )

        # Raise and allow global exception handler to catch
        raise

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
             Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error(
          "Exception occured when retrieving payment-related details for project ID: #{id}: (#{e})"
        )

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt get_payment_related_details again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

      Rails.logger.info("Finished retrieving payment-related details for project ID: #{id}")

      {
        'grant_award': restforce_response.Grant_Award__c,
        'grant_percentage': restforce_response.Grant_Percentage__c
      }

    end

    def get_agreed_project_costs(salesforce_case_id)

      Rails.logger.info("Retrieving agreed project costs for salesforce case ID: #{salesforce_case_id}")

      retry_number = 0

      begin

        restforce_response = @client.query(
          "SELECT SUM(Costs__c), SUM(Vat__c), Cost_heading__c FROM Project_Cost__c WHERE Case__c = '#{salesforce_case_id}' GROUP BY Cost_heading__c"
        )

        if restforce_response.length == 0

          error_msg = "No project costs found when retrieving agreed project costs for salesforce case ID: #{salesforce_case_id}"

          Rails.logger.error(error_msg)

          raise Restforce::NotFoundError.new(error_msg, { status: 500 } )

        end

        restforce_response

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
             Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error(
          "Exception occured when retrieving agreed project costs for salesforce case ID: #{salesforce_case_id}: (#{e})"
        )

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt get_agreed_project_costs again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to upsert salesforce objects needed for an expression of interest
    #
    # @param [PaExpressionOfInterest] an expression of interest captured so far
    # @param [User] instance of current User
    # @param [Organisation] instance of current User's organisation
    #
    # @return [Hash] A Hash, currently containing the salesforce references to the PEF, Contact and Organisation Salesforce objects
    def create_expression_of_interest(expression_of_interest, user, organisation)

      retry_number = 0

      begin

        salesforce_account_id = create_organisation_in_salesforce(organisation)

        salesforce_contact_id = upsert_contact_in_salesforce(user, salesforce_account_id)

        salesforce_expression_of_interest_id = @client.upsert!(
          'Expression_Of_Interest__c',
          'Expression_Of_Interest_external_ID__c',
          Expression_Of_Interest_external_ID__c: expression_of_interest.id,
          Heritage_Focus__c: expression_of_interest.heritage_focus,
          Can_Contact_Applicant__c: false, 
          Potential_Funding_Amount__c: expression_of_interest.potential_funding_amount,
          Previous_Fund_Contact__c: expression_of_interest.previous_contact_name,
          What_Project_Does__c: expression_of_interest.what_project_does,
          Programme_Outcomes__c: expression_of_interest.programme_outcomes,
          Project_Reasons__c: expression_of_interest.project_reasons,
          Timescales__c: expression_of_interest.project_timescales, 
          Project_Title__c: expression_of_interest.working_title,
          Overall_cost__c: expression_of_interest.overall_cost,
          Likely_Submission_Description__c: expression_of_interest.likely_submission_description,
          Contact__c: salesforce_contact_id,
          Name_of_your_organisation__c: salesforce_account_id
        )

        Rails.logger.info(
          'Created an expression of interest record in Salesforce with ' \
          "reference: #{salesforce_expression_of_interest_id}"
        )

        {
          salesforce_account_id: salesforce_account_id,
          salesforce_contact_id: salesforce_contact_id,
          salesforce_expression_of_interest_id: salesforce_expression_of_interest_id,
          salesforce_expression_of_interest_reference: get_salesforce_expression_of_interest_reference(expression_of_interest)
        }

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
             Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error(
          'Error creating an expression of interest record in Salesforce using pa_expression_of_interest ' \
          "#{expression_of_interest.id}, user #{user.id} and organisation #{organisation.id}"
        )

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt create_expression_of_interest again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to upsert salesforce objects needed for a project enquiry
    # Restforce documentation: https://github.com/restforce/restforce#upsert indicates no account
    # reference returned from Salesforce API upon upsert - but it is now.
    #
    # @param [PaProjectEnquiry] project_enquiry An instance of PaProjectEnquiry
    # @param [User] user An instance of User
    # @param [Organisation] organisation An instance of Organisation
    #
    # @return [Hash] A Hash, currently containing the salesforce references to the PEF,
    #                Contact and Organisation Salesforce objects
    def create_project_enquiry(project_enquiry, user, organisation)

      Rails.logger.info(
        "Begin creating organisation, contact and project enquiry objects in Salesforce"
      )

      retry_number = 0

      begin
        
        salesforce_account_id = create_organisation_in_salesforce(organisation)

        salesforce_contact_id = upsert_contact_in_salesforce(user, salesforce_account_id)

        salesforce_project_enquiry_id = @client.upsert!(
          'Project_Enquiry__c',
          'Project_Enquiry_external_ID__c',
          Project_Enquiry_external_ID__c: project_enquiry.id,
          Heritage_Focus__c: project_enquiry.heritage_focus,
          Likely_cost__c: project_enquiry.project_likely_cost,
          Can_Contact_Applicant__c: false, 
          Potential_Funding_Amount__c: project_enquiry.potential_funding_amount,
          Previous_Fund_Contact__c: project_enquiry.previous_contact_name,
          What_Project_Does__c: project_enquiry.what_project_does,
          Programme_Outcomes__c: project_enquiry.programme_outcomes,
          Project_Reasons__c: project_enquiry.project_reasons,
          Project_Participants__c: project_enquiry.project_participants,
          Timescales__c: project_enquiry.project_timescales, 
          Project_Title__c: project_enquiry.working_title,
          Contact__c: salesforce_contact_id,
          Name_of_your_organisation__c: salesforce_account_id
        )
 
        Rails.logger.info(
          "Created a project enquiry record in Salesforce with reference: #{salesforce_project_enquiry_id}"
        )

        {
          salesforce_account_id: salesforce_account_id,
          salesforce_contact_id: salesforce_contact_id,
          salesforce_project_enquiry_id: salesforce_project_enquiry_id,
          salesforce_project_enquiry_reference: get_salesforce_salesforce_project_enquiry_reference(project_enquiry)
        }

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
             Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error(
          "Error creating a project enquiry record in Salesforce using pa_project_enquiry #{project_enquiry.id}," \
          " user #{user.id} and organisation #{organisation.id}"
        )

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt create_project_enquiry again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end  

      end

    end

    def create_project(funding_application, user, organisation)

      Rails.logger.info(
        "Begin creating organisation, contact and project objects in Salesforce"
      )

      retry_number = 0

      begin

        salesforce_account_id = create_organisation_in_salesforce(organisation)

        create_legal_signatories_in_salesforce(
          organisation.legal_signatories,
          user,
          salesforce_account_id
        )

        salesforce_contact_id = upsert_contact_in_salesforce(
          user,
          salesforce_account_id
        )

        permission_type = translate_permission_type_for_salesforce(
          funding_application.open_medium.permission_type
        )
        
        attracts_visitors = translate_attracts_visitors_for_salesforce(
          funding_application.open_medium.heritage_attracts_visitors
        )

        capital_work_ownership_type = translate_ownership_type_for_salesforce(
          funding_application.open_medium.ownership_type
        )

        capital_work_details = get_relevant_ownership_type_description(
          funding_application.open_medium
        )

        formal_designations = translate_formal_designations_for_salesforce(
          funding_application.open_medium.heritage_designations
        )

        same_location = do_project_and_organisation_addresses_match?(
          funding_application,
          organisation
        )
        
        salesforce_project_reference = @client.upsert!(
          'Case',
          'ApplicationId__c',
          ApplicationId__c: funding_application.id,
          AccountId: salesforce_account_id,
          Project_Title__c: funding_application.open_medium.project_title,
          Project_Street__c: [
            funding_application.open_medium.line1,
            funding_application.open_medium.line2,
            funding_application.open_medium.line3
          ].compact.join(', '),
          Project_City__c: funding_application.open_medium.townCity,
          Project_County__c: funding_application.open_medium.county,
          Project_Post_Code__c: funding_application.open_medium.postcode,
          Is_Project_organisation_address_same__c: same_location,
          Project_Start_Date__c: funding_application.open_medium.start_date,
          Project_End_Date__c: funding_application.open_medium.end_date,
          Project_Description__c: funding_application.open_medium.description,
          What_difference_will_your_project_make__c: funding_application.open_medium.difference,
          Why_does_your_project_Important__c: funding_application.open_medium.matter,
          Description_about_Heritage_in_Project__c: funding_application.open_medium.heritage_description,
          Why_your_Org_should_run_this_project__c: funding_application.open_medium.best_placed_description,
          Outcome_Wide_range_of_people__c: funding_application.open_medium.involvement_description,
          Do_you_need_permission_from_anyone_else__c: permission_type,
          Details_of_permission_for_project__c: funding_application.open_medium.permission_description,
          Any_capital_work_as_part_of_this__c: funding_application.open_medium.capital_work,
          Delivered_by_partnership__c: funding_application.open_medium.is_partnership,
          Delivery_partner_details__c: funding_application.open_medium.partnership_details,
          Information_not_publically_available__c: funding_application.open_medium.declaration_reasons_description,
          Involve_in_research__c: funding_application.open_medium.user_research_declaration,
          Keep_Informed__c: funding_application.open_medium.keep_informed_declaration,
          Heritage_will_be_in_better_condition__c: funding_application.open_medium.outcome_2,
          Outcome_Heritage_in_better_condition__c: funding_application.open_medium.outcome_2_description,
          Identified_and_better_explained__c: funding_application.open_medium.outcome_3,
          Outcome_Heritage_identified_explained__c: funding_application.open_medium.outcome_3_description,
          People_will_have_developed_skills__c: funding_application.open_medium.outcome_4,
          Outcome_Developed_Skills__c: funding_application.open_medium.outcome_4_description,
          People_will_have_learned_about_heritage__c: funding_application.open_medium.outcome_5,
          Outcome_Learning_about_heritage__c: funding_application.open_medium.outcome_5_description,
          People_will_have_greater_wellbeing__c: funding_application.open_medium.outcome_6,
          Outcome_Greater_well_being__c: funding_application.open_medium.outcome_6_description,
          The_organisation_will_be_more_resilient__c: funding_application.open_medium.outcome_7,
          Outcome_Resilient_organisation__c: funding_application.open_medium.outcome_7_description,
          A_better_place_to_live_work_or_visit__c: funding_application.open_medium.outcome_8,
          Outcome_Better_place_to_live__c: funding_application.open_medium.outcome_8_description,
          The_local_economy_will_be_boosted__c: funding_application.open_medium.outcome_9,
          Outcome_Boosted_Economy__c: funding_application.open_medium.outcome_9_description,
          Project_involved_acquisition__c: funding_application.open_medium.acquisition,
          Heritage_considered_to_be_at_risk__c: funding_application.open_medium.heritage_at_risk,
          Details_for_facing_risks_after_complete__c: funding_application.open_medium.heritage_at_risk_description,
          Does_heritage_attract_visitors__c: attracts_visitors,
          No_of_visitor_receive_last_FY__c: funding_application.open_medium.visitors_in_last_financial_year,
          No_of_visitor_expected_after_project__c: funding_application.open_medium.visitors_expected_per_year,
          How_will_your_project_be_managed__c: funding_application.open_medium.management_description,
          How_will_you_evaluate_your_project__c: funding_application.open_medium.evaluation_description,
          Details_of_Jobs_will_be_created__c: funding_application.open_medium.jobs_or_apprenticeships_description,
          Special_access_to_NL_players__c: funding_application.open_medium.acknowledgement_description,
          Advice_received_in_planning_and_whom__c: funding_application.open_medium.received_advice_description,
          First_Application_to_NLHF__c: funding_application.open_medium.first_fund_application ? 'Yes' : 'No',
          Most_Recent_Project_Reference_Number__c: funding_application.open_medium.recent_project_reference,
          Most_Recent_Proj_Ref_Title__c: funding_application.open_medium.recent_project_title,
          Why_project_to_go_ahead_now__c: funding_application.open_medium.why_now_description,
          Measure_to_increase_positive_impact__c: funding_application.open_medium.environmental_impacts_description,
          Capital_work_owner__c: capital_work_ownership_type,
          Capital_work_details__c: capital_work_details,
          Heritage_Formal_designation__c: formal_designations,
          Other_Formal_Designation__c: funding_application.open_medium.hd_other_description,
          Grade_I_or_A_buildings__c: funding_application.open_medium.hd_grade_1_description,
          Grade_II_or_B_buildings__c: funding_application.open_medium.hd_grade_2_b_description,
          Grade_II_or_C_buildings__c: funding_application.open_medium.hd_grade_2_c_description,
          Local_List__c: funding_application.open_medium.hd_local_list_description,
          Scheduled_Ancient_Monument__c: funding_application.open_medium.hd_monument_description,
          Registered_Historic_ship_Certificate_no__c: funding_application.open_medium.hd_historic_ship_description,
          Grade_I_listed_park_or_garden_Inventory__c: funding_application.open_medium.hd_grade_1_park_description,
          Grade_II_listed_park_or_garden_Inventory__c: funding_application.open_medium.hd_grade_2_park_description,
          Grade_II_listed_parkgarden_Inventory_ast__c: funding_application.open_medium.hd_grade_2_star_park_description,
          ContactId: salesforce_contact_id, 
          RecordTypeId: get_salesforce_record_type_id('Medium', 'Case'))

        Rails.logger.info(
          'Created a project record in Salesforce with reference: ' \
          "#{salesforce_project_reference}"
        )

        create_associated_records_in_salesforce(
          funding_application,
          salesforce_project_reference
        )

        create_open_medium_files_in_salesforce(
          funding_application,
          salesforce_project_reference
        )

        external_reference = get_external_reference_number_for_project(
          salesforce_project_reference
        )

        {
          salesforce_account_id: salesforce_account_id,
          salesforce_contact_id: salesforce_contact_id,
          salesforce_project_reference: salesforce_project_reference,
          external_reference: external_reference
        }

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error(
          'Error creating a project record in Salesforce using ' \
          "funding_application #{funding_application.id}," \
          " user #{user.id} and organisation #{organisation.id}"
        )

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt create_project again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to retrieve the external reference number (e.g. HG-12-34567) for
    # a given Salesforce Case ID
    #
    # @param [String] salesforce_project_reference The unique identifier for
    #                                              a Salesforce Case
    #
    # @return [String] An externally-used reference number in the format
    #                  HG-12-34567
    def get_external_reference_number_for_project(salesforce_project_reference)

      retry_number = 0

      begin

        salesforce_response = @client.select(
          'Case',
          salesforce_project_reference,
          ['Project_Reference_Number__c'],
          'ID'
        )

        salesforce_response.Project_Reference_Number__c

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error(
          'Error retrieving external reference number for Salesforce Case ' \
          "ID: #{salesforce_project_reference}"
        )

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            'Will attempt get_external_reference_number_for_project again, ' \
            "retry number #{retry_number} after a sleeping for up to " \
            "#{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to update the can_contact_applicant part of a project enquiry on Salesforce
    #
    # @param [PaProjectEnquiry] project_enquiry An instance of PaProjectEnquiry
    # @param [User] user An instance of User
    def update_project_enquiry_can_contact_applicant(project_enquiry, user)
      
      retry_number = 0

      begin

        @client.update!(
          'Project_Enquiry__c',
          Id: project_enquiry.salesforce_project_enquiry_id,
          Can_Contact_Applicant__c: (user.agrees_to_contact.present?) ? user.agrees_to_contact : false
        )

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
             Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error updating Can Contact Applicant for user #{user.id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt update_project_enquiry_can_contact_applicant again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to update the can_contact_applicant part of an expression of interest on Salesforce
    #
    # @param [PaExpressionOfInterest] expression_of_interest An instance of PaExpressionOfInterest
    # @param [User] user An instance of User
    def update_expression_of_interest_can_contact_applicant(expression_of_interest, user)

      retry_number = 0

      begin

        salesforce_expression_of_interest = @client.find(
          'Expression_Of_Interest__c',
          expression_of_interest.id,
          'Expression_Of_Interest_external_ID__c'
        )

        @client.update!(
          'Expression_Of_Interest__c',
          Id: salesforce_expression_of_interest[:Id],
          Can_Contact_Applicant__c: (user.agrees_to_contact.present?) ? user.agrees_to_contact : false
        )

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
             Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error updating Can Contact Applicant for user #{user.id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt update_expression_of_interest_can_contact_applicant again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to update the agrees to user research part of a Contact on Salesforce
    #
    # @param [User] user An instance of a User
    def update_agrees_to_user_research(user)

      retry_number = 0

      begin
        
        @client.update!(
          'Contact',
          Id: user.salesforce_contact_id,
          Agrees_To_User_Research__c: (user.agrees_to_user_research.present?) ? user.agrees_to_user_research : false
        )

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
             Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error updating agrees to user research for user #{user.id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt update_agrees_to_user_research again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to check Salesforce to see if a legal agreement is in place for
    # a given Project.
    #
    # Takes the Salesforce id as a parameter, rather than a UUID for
    # a FundingApplication. This is because Salesforce currently stores
    # the UUID of a Project for a £3,000 to £10,000 application and the UUID
    # of a FundingApplication for everything else.
    #
    # Retries if initial call unsuccessful.
    #
    # @param [String] salesforce_external_id Can be a FundingApplication.id or a Project.id
    #
    # @return [Boolean] Returns True if the Legal_agreement_in_place__c field
    #                   in Salesforce has been set, otherwise False.
    def legal_agreement_in_place?(salesforce_external_id)

      retry_number = 0

      begin

        record_type_id =
          @client.query_all("select Legal_agreement_in_place__c from Case " \
            "where ApplicationId__c ='#{salesforce_external_id}'")

        if record_type_id.length != 1

          error_msg = "Row not found for Case. " \
            "Checking funding application id : '#{salesforce_external_id}'"

          Rails.logger.error(error_msg)

        end

        record_type_id&.first&.Legal_agreement_in_place__c

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error checking if legal agreement in place " \
          "for funding application id: #{salesforce_external_id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt legal_agreement_in_place? again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to orchestrate creating the salesforce records needed when 
    # an applicant requests a payment.
    # creates a record for bank account, then payment request, then 
    # joins the two with a junction object.
    # Finally uploads evidence of the bank account against the bank
    # account record.
    #
    # Responsible for retries of its inner scope calls
    # 
    # @param [FundingApplication] funding_application An FundingApplication instance
    # @param [PaymentRequest] payment_request A PaymentRequest instance
    def upsert_payment_records(funding_application, payment_request)

      retry_number = 0

      begin
        
        salesforce_bank_account_id = \
          upsert_bank_account_details(funding_application)
        
        salesforce_payment_request_id = \
          upsert_payment_request_details(funding_application, payment_request)

        upsert_bank_account_payment_request_junction(salesforce_bank_account_id, \
          salesforce_payment_request_id)

        create_file_in_salesforce(
          funding_application.payment_details.evidence_file,
          'Evidence of bank account',
          salesforce_bank_account_id
        ) if funding_application.payment_details.evidence_file.present?


      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt upsert_payment_records again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to find a Project Owner Name.  For example an Investment 
    # Manager responsible for a project
    #
    # Responsible for retries of its inner scope calls
    # 
    # @param [salesforce_case_id] String A Case Id reference known to Salesforce 
    # @return [String] Name. Project Owner name
    def project_owner_name(salesforce_case_id)

      retry_number = 0

      begin

        record_type_id = 
          @client.query_all("SELECT Owner.name from Case " \
            "where Id ='#{salesforce_case_id}'")

        if record_type_id.length != 1

          error_msg = "Owner name not found for Case. " \
            "Checking case id : '#{salesforce_case_id}'"

          Rails.logger.error(error_msg)

        end

        record_type_id&.first&.Owner.Name

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error finding project owner name " \
          "for case id: #{salesforce_case_id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt project_owner_name again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to find a Project Owner's details.
    #
    # Responsible for retries of its inner scope calls
    #
    # @param [salesforce_case_id] String A Case Id reference known to Salesforce
    # @return [<Restforce::SObject>] result&first.  A Restforce object
    #                                               with query results
    def project_owner_details(salesforce_case_id)
      retry_number = 0

      begin

        result = @client.query_all(
            "SELECT Owner.name, Owner.Email from Case " \
            "where ID = '#{salesforce_case_id}'"
        )  

        if result.length != 1 

          error_msg = "Project owner details not found for Case. " \
            "Checking case id : '#{salesforce_case_id}'"

          Rails.logger.error(error_msg)

        end

        result&.first

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error finding project owner details " \
          "for case id: #{salesforce_case_id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt project_owner_details again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to find a Project's details.
    # Currently used within the check-project-details route
    #
    # Responsible for retries of its inner scope calls
    # 
    # @param [salesforce_case_id] String A Case Id reference known to Salesforce 
    # @return [<Restforce::SObject] result&.first.  A Restforce object 
    #                                               with query results
    def project_details(salesforce_case_id)
      retry_number = 0

      begin

        result = 
          @client.query_all("SELECT Owner.name, Account.Name, Project_Title__c, " \
            "Grant_Award__c, Grant_Percentage__c, Total_Development_Income__c, " \
              "Total_Non_Cash_contributions__c, Total_Volunteer_Contributions__c, " \
                "Grant_Expiry_Date__c, Project_Reference_Number__c, Contact.Name, Submission_Date_Time__c " \
                  "from Case " \
                    "where ID = '#{salesforce_case_id}'")  

        if result.length != 1 

          error_msg = "Project details not found for Case. " \
            "Checking case id : '#{salesforce_case_id}'"

          Rails.logger.error(error_msg)

        end

        result&.first

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error finding project details " \
          "for case id: #{salesforce_case_id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt project_details again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to find a Project's costs.
    # Currently used within the check-project-details route
    #
    # Responsible for retries
    # 
    # @param [salesforce_case_id] String A Case Id reference known to Salesforce 
    # @return [<Restforce::SObject] result.  A Restforce collection 
    #                                        with query results
    def project_costs(salesforce_case_id)
      retry_number = 0

      begin

        result = 
          @client.query_all("SELECT Cost_Heading__c, Costs__c, Vat__c, Project_Cost_Description__c " \
            "FROM Project_Cost__c " \
              "where Case__c = '#{salesforce_case_id}'")  

        if result.length != 1 

          error_msg = "Project costs not found for Case. " \
            "Checking case id : '#{salesforce_case_id}'"

          Rails.logger.error(error_msg)

        end

        result

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error finding project costs " \
          "for case id: #{salesforce_case_id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt project_costs again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to find a Project's cash contributions.
    # Currently used within the check-project-details route
    #
    # Responsible for retries
    # 
    # @param [salesforce_case_id] String A Case Id reference known to Salesforce 
    # @return [<Restforce::SObject] result.  A Restforce collection 
    #                                        with query results
    def cash_contributions(salesforce_case_id)
      retry_number = 0

      begin

        result = 
          @client.query_all("SELECT Description_for_cash_contributions__c, " \
            "Amount_you_have_received__c, " \
              "Secured_non_cash_contributions__c, Secured__c " \
                "FROM Project_Income__c " \
                  "where Case__c = '#{salesforce_case_id}'")  

        if result.length != 1 

          error_msg = "cash contributions not found for Case. " \
            "Checking case id : '#{salesforce_case_id}'"

          Rails.logger.error(error_msg)

        end

        result

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error finding cash contributions " \
          "for case id: #{salesforce_case_id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt to get cash contributions again, " \
            "retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to find a Project's approved purposes.
    # Currently used within the check-project-details route
    #
    # Responsible for retries of its inner scope calls
    # 
    # @param [salesforce_case_id] String A Case Id reference known to Salesforce 
    # @return [<Restforce::SObject] result.  A Restforce collection 
    #                                        with query results
    def project_approved_purposes(salesforce_case_id)
      retry_number = 0

      begin

        result = 
          @client.query_all("SELECT Approved_Purposes__c, Final_summery_of_achievements__c " \
            "FROM Approved__c " \
              "where Project__c = '#{salesforce_case_id}'")  

        if result.length < 1 

          error_msg = "Project approved purposes not found for Case. " \
            "Checking case id : '#{salesforce_case_id}'"

          Rails.logger.error(error_msg)

        end

        result

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error finding project approved purposes " \
          "for case id: #{salesforce_case_id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt project_approved_purposes again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    
    # Method to check Salesforce to see if a legal agreement is in place
    # True is returned if a legal agreement is in place.
    # Takes and id as a parameter.  Because Salesforce stores project ids for smalls and
    # funding_ids for everything else.
    #
    # Retries if initial call unsuccessful.
    #
    # @param [String] salesforce_external_id Can be a FundingApplication.id or a Project.id
    #
    # @return [Boolean] True if a legal agreement is in place for the funding_application
    def legal_agreement_in_place?(salesforce_external_id)    

      retry_number = 0

      begin

        record_type_id = 
          @client.query_all("select Legal_agreement_in_place__c from Case " \
            "where ApplicationId__c ='#{salesforce_external_id}'")

        if record_type_id.length != 1

          error_msg = "Row not found for Case. " \
            "Checking funding application id : '#{salesforce_external_id}'"

          Rails.logger.error(error_msg)

        end

        record_type_id&.first&.Legal_agreement_in_place__c

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error checking if application awarded " \
          "for funding application id: #{salesforce_external_id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt legal_agreement_in_place? again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to inform Investment Manager that the Legal agreement documents
    # are submitted 
    # Updates Legal agreement documents submitted
    #
    # Retries if initial call unsuccessful.
    #
    # @param [salesforce_case_id] String A Case Id reference known to Salesforce 
    def update_legal_agreement_documents_submitted(salesforce_case_id)
      
      retry_number = 0

      begin

        @client.update!(
          'Case',
          Id: salesforce_case_id,
          Legal_agreement_documents_submitted__c: true
        )

      rescue Restforce::MatchesMultipleError, 
        Restforce::UnauthorizedError,
          Restforce::EntityTooLargeError, 
            Restforce::ResponseError => e

        Rails.logger.error("Error updating " \
          "update_legal_agreement_documents_submitted for " \
            "salesforce_case_id #{salesforce_case_id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt " \
              "update_legal_agreement_documents_submitted again, " \
                "retry number #{retry_number} " \
                  "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    def upload_additional_evidence_files(
      additional_evidence_files,
      type,
      salesforce_case_id
    )
      
      create_multiple_files_in_salesforce(
        additional_evidence_files,
        type,
        salesforce_case_id
      )
    
    end

    def upload_signed_terms_and_conditions(
      signed_terms_and_conditions_file,
      type,
      salesforce_case_id
    )

      create_file_in_salesforce(
        signed_terms_and_conditions_file,
        type,
        salesforce_case_id
      )

    end

    # Method to check Salesforce to see if an application is awarded
    # True is returned if a awarded.
    # Takes and id as a parameter.  Because Salesforce stores project ids for smalls and
    # funding_ids for everything else.
    #
    # Retries if initial call unsuccessful.
    #
    # @param [String] salesforce_external_id Can be a FundingApplication.id or a Project.id
    #
    # @return [Boolean] True if the funding_application is ready to start the payment journey.
    def is_project_awarded(salesforce_external_id)    

      retry_number = 0

      begin

        record_type_id = 
          @client.query_all("select Start_the_legal_agreement_process__c from Case " \
            "where ApplicationId__c ='#{salesforce_external_id}'")

        if record_type_id.length != 1
          error_msg = "Row not found for Case. " \
            "Checking funding application id : '#{salesforce_external_id}'"
          Rails.logger.error(error_msg)

        end

        record_type_id&.first&.Start_the_legal_agreement_process__c

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e
        Rails.logger.error("Error checking if appliaction awarded " \
          "for funding application id: #{salesforce_external_id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1
          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt is_project_awarded again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )
          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end
      
    end

    # Method to find additional grant conditions for an awarded project.
    # Currently used within the terms route
    #
    # Responsible for retries
    # 
    # @param [salesforce_case_id] String A Case Id reference known to Salesforce 
    # @return [<Restforce::SObject] result.  A Restforce collection 
    #                                        with query results
    def additional_grant_conditions(salesforce_case_id)
      retry_number = 0

      begin

        result = 
          @client.query_all("SELECT Additional_Grant_Condition_Text__c, Summary_of_progress__c " \
            "FROM Additional_Grant_Condition__c " \
              "where Project__c = '#{salesforce_case_id}'")  

        if result.length < 1 

          info_msg = "Additional grant conditions not found for Case: " \
            "'#{salesforce_case_id}'"

          Rails.logger.info(info_msg)

        end

        result

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error finding Additional grant conditions " \
          "for case id: #{salesforce_case_id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt additional_grant_conditions again, " \
              "retry number #{retry_number} " \
                "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to find all large projects in Salesforce that have an email address
    # matching the current user logged into Funding Frontend.
    # Currently used by dashboard controller
    #
    # @param [email] Current logged in users' email
    # @return [<Restforce::SObject] result.  A Restforce collection 
    #                                        with query results
    def select_large_applications(email)

      retry_number = 0

      begin

      large_applications = []

      user = @client.query_all("SELECT AccountId, Id FROM Contact WHERE Id IN  " \
        "(SELECT ContactId FROM User where email = '#{email}') ")

      if user.length > 1 
        info_msg = "Multiple account IDs found for email: " \
        "'#{email}'"

        Rails.logger.error(info_msg)
      end

      unless user&.first.values.any? { | detail |  detail.nil? }
        large_applications = 
        @client.query_all("SELECT Project_Title__c, Id, " \
          "recordType.DeveloperName FROM Case WHERE  " \
            "AccountId = '#{user.first[:AccountId]}' AND " \
              "contactId = '#{user.first[:Id]}' AND " \
                "Application_Submitted__c = TRUE AND " \
                  "Start_the_legal_agreement_process__c = TRUE")
      end

      return large_applications

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
        Restforce::ResponseError => e
        Rails.logger.error("Error retrieving large applications " \
          "for funding user with email: #{email}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1
          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt to retrieve large applications again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )
          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end
      end
    end

    
    private

    # Method used to orchestrate creation of associated records in Salesforce
    #
    # @param [FundingApplication] funding_application An instance of
    #                                                 FundingApplication
    # @param [String] salesforce_project_reference A unique identifier for
    #                                              a Salesforce Case
    def create_associated_records_in_salesforce(
      funding_application,
      salesforce_project_reference
    )

      Rails.logger.debug(
        'Orchestration creation of associated Salesforce records for ' \
        "funding_application ID: #{funding_application.id}"
      )

      create_project_costs_in_salesforce(
        funding_application.project_costs,
        salesforce_project_reference
      ) if funding_application.project_costs.any?

      create_non_cash_contributions_in_salesforce(
        funding_application.non_cash_contributions,
        salesforce_project_reference
      ) if funding_application.non_cash_contributions.any?

      create_cash_contributions_in_salesforce(
        funding_application.cash_contributions,
        salesforce_project_reference
      ) if funding_application.cash_contributions.any?

      create_volunteers_in_salesforce(
        funding_application.volunteers,
        salesforce_project_reference
      ) if funding_application.volunteers.any?

      Rails.logger.debug(
        'Finished orchestrating creation of associated Salesforce records ' \
        "for funding_application ID: #{funding_application.id}"
      )

    end

    # Method used to orchestration creation of files in Salesforce that are
    # associated with an OpenMedium application
    #
    # @param [FundingApplication] funding_application An instance of
    #                                                 FundingApplication
    def create_open_medium_files_in_salesforce(
      funding_application,
      salesforce_project_reference
    )

      create_file_in_salesforce(
        funding_application.open_medium.governing_document_file,
        'Governing Document',
        salesforce_project_reference
      ) if funding_application.open_medium.governing_document_file.present?

      create_file_in_salesforce(
        funding_application.open_medium.ownership_file,
        'Ownership',
        salesforce_project_reference
      ) if funding_application.open_medium.ownership_file.present?

      create_file_in_salesforce(
        funding_application.open_medium.capital_work_file,
        'Capital Work',
        salesforce_project_reference
      ) if funding_application.open_medium.capital_work_file.present?

      create_file_in_salesforce(
        funding_application.open_medium.partnership_agreement_file,
        'Partnership Agreement',
        salesforce_project_reference
      ) if funding_application.open_medium.partnership_agreement_file.present?

      create_file_in_salesforce(
        funding_application.open_medium.risk_register_file,
        'Risk Register',
        salesforce_project_reference
      ) if funding_application.open_medium.risk_register_file.present?

      create_file_in_salesforce(
        funding_application.open_medium.project_plan_file,
        'Project Plan',
        salesforce_project_reference
      ) if funding_application.open_medium.project_plan_file.present?

      create_file_in_salesforce(
        funding_application.open_medium.full_cost_recovery_file,
        'Full Cost Recovery',
        salesforce_project_reference
      ) if funding_application.open_medium.full_cost_recovery_file.present?

      create_multiple_files_in_salesforce(
        funding_application.open_medium.accounts_files,
        'Accounts',
        salesforce_project_reference
      ) if funding_application.open_medium.accounts_files.any?

      create_multiple_files_in_salesforce(
        funding_application.open_medium.job_description_files,
        'Job Descriptions',
        salesforce_project_reference
      ) if funding_application.open_medium.job_description_files.any?

      create_multiple_files_in_salesforce(
        funding_application.open_medium.work_brief_files,
        'Work Briefs',
        salesforce_project_reference
      ) if funding_application.open_medium.work_brief_files.any?

      create_multiple_files_in_salesforce(
        funding_application.open_medium.project_image_files,
        'Project Images',
        salesforce_project_reference
      ) if funding_application.open_medium.project_image_files.any?

      funding_application.evidence_of_support.each_with_index do |eos, idx|

        create_file_in_salesforce(
          eos.evidence_of_support_files,
          "Evidence of support ##{ idx + 1 }",
          salesforce_project_reference,
          eos.description
        )

      end

    end

    # Method used to orchestrate creation of Volunteer records in Salesforce
    #
    # @param [ActiveRecord::Associations] volunteers A collection of Volunteer
    #                                                objects
    # @param [String] salesforce_project_reference A unique identifier for
    #                                              a Salesforce Case
    def create_volunteers_in_salesforce(
      volunteers,
      salesforce_project_reference
    )

      Rails.logger.debug(
        'Creating volunteers in Salesforce for Salesforce project ' \
        "reference #{salesforce_project_reference}"
      )

      volunteers.each do |v|

          upsert_volunteer_by_external_id(
            v,
            salesforce_project_reference
          )

      end

      Rails.logger.debug(
        'Finished creating volunteers in Salesforce for Salesforce ' \
        "project reference #{salesforce_project_reference}"
      )

    end

    # Method used to orchestrate creation of ProjectCost records in Salesforce
    #
    # @param [ActiveRecord::Associations] project_costs A collection of
    #                                                  ProjectCost objects
    # @param [String] salesforce_project_reference A unique identifier for
    #                                              a Salesforce Case
    def create_project_costs_in_salesforce(
      project_costs,
      salesforce_project_reference
    )

      project_costs.each do |pc|

          upsert_project_cost_by_external_id(
            pc,
            salesforce_project_reference
          )

      end

    end

    # Method used to orchestrate creation of NonCashContribution records in
    # Salesforce
    #
    # @param [ActiveRecord::Associations] non_cash_contributions A collection
    #                                       of NonCashContribution objects
    # @param [String] salesforce_project_reference A unique identifier for
    #                                              a Salesforce Case
    def create_non_cash_contributions_in_salesforce(
      non_cash_contributions,
      salesforce_project_reference
    )

      non_cash_contributions.each do |ncc|

        upsert_non_cash_contribution_by_external_id(
          ncc,
          salesforce_project_reference
        )

      end

    end

    # Method used to orchestrate creation of CashContribution records in
    # Salesforce
    #
    # @param [ActiveRecord::Associations] cash_contributions A collection
    #                                       of CashContribution objects
    # @param [String] salesforce_project_reference A unique identifier for
    #                                              a Salesforce Case
    def create_cash_contributions_in_salesforce(
      cash_contributions,
      salesforce_project_reference
    )

      cash_contributions.each do |cc|

        upsert_cash_contribution_by_external_id(
          cc,
          salesforce_project_reference
        )

      end

    end

    # Method used to upsert a new VolunteerNonCashContributions__c record in
    # Salesforce from a corresponding Volunteer object in funding-frontend
    #
    # @param [Volunteer] volunteer An instance of a Volunteer
    # @param [String] salesforce_project_reference A unique identifier for
    #                                              a Salesforce Case
    def upsert_volunteer_by_external_id(
      volunteer,
      salesforce_project_reference
    )

      Rails.logger.info(
        'Upserting volunteer in Salesforce using ' \
        'VolunteerExternalId__c ' \
        "#{volunteer.id}"
      )

      salesforce_record = @client.upsert!(
        'Volunteer_Non_Cash_Contributions__c',
        'VolunteerExternalId__c',
        VolunteerExternalId__c: volunteer.id,
        Case__c: salesforce_project_reference,
        Description__c: volunteer.description,
        Hours__c: volunteer.hours
      )

      Rails.logger.info(
        'Finished upserting volunteer in Salesforce using ' \
        'VolunteerExternalId__c ' \
        "#{volunteer.id}"
      )

      volunteer.update(
        salesforce_external_id: salesforce_record
      ) if volunteer.salesforce_external_id.nil?

    end

    # Method used to upsert a new ProjectCost__c record in Salesforce from a
    # corresponding ProjectCost object in funding-frontend
    #
    # @param [ProjectCost] project_cost An instance of a ProjectCost
    # @param [String] salesforce_project_reference A unique identifier for
    #                                              a Salesforce Case
    def upsert_project_cost_by_external_id(
      project_cost,
      salesforce_project_reference
    )

      Rails.logger.info(
        'Upserting ProjectCost in Salesforce using ' \
        'ProjectCost_Ref_ID__c ' \
        "#{project_cost.id}"
      )

      cost_type = translate_cost_type_for_salesforce(
        project_cost.cost_type
      )

      salesforce_record = @client.upsert!(
        'Project_Cost__c',
        'ProjectCost_Ref_ID__c',
        ProjectCost_Ref_ID__c: project_cost.id,
        Case__c: salesforce_project_reference,
        Project_Cost_Description__c: project_cost.description,
        Costs__c: project_cost.amount,
        Vat__c: project_cost.vat_amount,
        Cost_heading__c: cost_type
      )

      Rails.logger.info(
        'Finished upserting ProjectCost in Salesforce using ' \
        'ProjectCost_Ref_ID__c ' \
        "#{project_cost.id}"
      )

      project_cost.update(
        salesforce_external_id: salesforce_record
      ) if project_cost.salesforce_external_id.nil?

    end

    # Method used to upsert a new VolunteerNonCashContributions__c record in
    # Salesforce from a corresponding NonCashContribution object in
    # funding-frontend
    #
    # @param [NonCashContribution] non_cash_contribution An instance of a
    #                                                    NonCashContribution
    # @param [String] salesforce_project_reference A unique identifier for
    #                                              a Salesforce Case
    def upsert_non_cash_contribution_by_external_id(
      non_cash_contribution,
      salesforce_project_reference
    )

      Rails.logger.info(
        'Upserting non_cash_contribution in Salesforce using ' \
        'NonCashContributionExternalId__c ' \
        "#{non_cash_contribution.id}"
      )

      salesforce_record = @client.upsert!(
        'Volunteer_Non_Cash_Contributions__c',
        'NonCashContributionExternalId__c',
        NonCashContributionExternalId__c: non_cash_contribution.id,
        Case__c: salesforce_project_reference,
        Description__c: non_cash_contribution.description,
        Estimated_Value__c: non_cash_contribution.amount
      )

      Rails.logger.info(
        'Finished upserting non_cash_contribution in Salesforce using ' \
        'NonCashContributionExternalId__c ' \
        "#{non_cash_contribution.id}"
      )

      non_cash_contribution.update(
        salesforce_external_id: salesforce_record
      ) if non_cash_contribution.salesforce_external_id.nil?

    end

    # Method used to upsert a new CashContributions__c record in
    # Salesforce from a corresponding CashContribution object in
    # funding-frontend
    #
    # @param [CashContribution] cash_contribution An instance of a
    #                                             CashContribution
    # @param [String] salesforce_project_reference A unique identifier for
    #                                              a Salesforce Case
    def upsert_cash_contribution_by_external_id(
      cash_contribution,
      salesforce_project_reference
    )

      Rails.logger.info(
        'Upserting cash_contribution in Salesforce using ' \
        'Contributions_ID__c ' \
        "#{cash_contribution.id}"
      )

      secured_value = translate_secured_for_salesforce(
        cash_contribution.secured
      )

      secured = cash_contribution.secured == 'yes_with_evidence' ||
        cash_contribution.secured == 'yes_no_evidence_yet'

      salesforce_record = @client.upsert!(
        'Project_Income__c',
        'Contributions_ID__c',
        Contributions_ID__c: cash_contribution.id,
        Case__c: salesforce_project_reference,
        Description_for_cash_contributions__c: cash_contribution.description,
        Amount_you_have_received__c: cash_contribution.amount,
        Secured_non_cash_contributions__c: secured_value,
        Secured__c: true
      )

      if cash_contribution.cash_contribution_evidence_files.attached?
        create_file_in_salesforce(
          cash_contribution.cash_contribution_evidence_files,
          'Cash Contribution Evidence',
          salesforce_record
        )
      end

      Rails.logger.info(
        'Finished upserting cash_contribution in Salesforce using ' \
        'Contributions_ID__c ' \
        "#{cash_contribution.id}"
      )

      cash_contribution.update(
        salesforce_external_id: salesforce_record
      ) if cash_contribution.salesforce_external_id.nil?

    end

    # Method to upsert a ContentVersion in Salesforce for a governing document
    #
    # @param [ActiveStorageBlob] file The governing document file to upload
    # @param [String] type The type of file to upload (e.g. 'governing document')
    # @param [String] salesforce_reference The Salesforce Case reference
    #                                              to link this upload to
    # @param [String] description A description of the file being uploaded
    def create_file_in_salesforce(
      file,
      type,
      salesforce_reference,
      description = nil
    )

      Rails.logger.info("Creating #{type} file in Salesforce")

      Rails.logger.debug('Using ApplicationHelper to create file')

      insert_salesforce_attachment(
        @client,
        file,
        type,
        salesforce_reference,
        description
      )

      Rails.logger.debug('Finished using ApplicationHelper to create file')

      Rails.logger.info("Finished creating #{type} file in Salesforce")

    end

    # Method to orchestrate creation of multiple files in Salesforce
    #
    # @param [ActiveStorageBlob] files The files to upload
    # @param [String] type The type of file to upload (e.g. 'accounts')
    # @param [String] salesforce_project_reference The Salesforce Case reference
    #                                              to link an uploaded file to
    # @param [String] description A description of the file being uploaded
    def create_multiple_files_in_salesforce(
      files,
      type,
      salesforce_project_reference,
      description = nil
    )

      Rails.logger.info("Creating #{type} files in Salesforce")

      files.each_with_index do |file, i|

        create_file_in_salesforce(
          file,
          "#{type} #{i + 1}",
          salesforce_project_reference,
          description
        )

      end

      Rails.logger.info("Finished creating #{type} files in Salesforce")

    end

    # Method to create Contact records in Salesforce for an organisation's
    # legal signatories
    #
    # @param [ActiveRecord::Associations] legal_signatories
    # @param [User] The user related to a funding application
    # @param [String] salesforce_account_id A Salesforce id for the Account
    #                                       (Organisation is an alias of
    #                                       Account)
    def create_legal_signatories_in_salesforce(
      legal_signatories,
      user,
      salesforce_account_id
    )

      legal_signatories.each do |ls|

        unless contact_is_legal_signatory?(user, ls)

          @client.upsert!(
            'Contact',
            'Contact_External_ID__c',
            Contact_External_ID__c: ls.id,
            LastName: ls.name,
            Email__c: ls.email_address,
            Email: ls.email_address,
            Phone: ls.phone_number,
            Is_Authorised_Signatory__c: true,
            AccountID: salesforce_account_id
          )

        end

      end

    end

    # Method to determine whether a user is also the legal signatory for a
    # funding application
    #
    # @param [User] user The user related to a funding_application
    # @param [LegalSignatory] legal_signatory A legal signatory related to
    #                                         a funding_application
    #
    # @return [Boolean] A Boolean flag to indicate whether or not the user
    #                   is also a legal signatory
    def contact_is_legal_signatory?(user, legal_signatory)

      user.email == legal_signatory.email_address

    end

    # Method to upsert a Salesforce Organisation record. Calling function
    # should handle exceptions/retries.
    #
    # @param [Organisation] organisation An instance of an Organisation object
    #
    # @return [String] A salesforce id for the Account (Organisation is an alias of Account)
    def create_organisation_in_salesforce(organisation)

      salesforce_account_id = find_matching_account_for_organisation(organisation)

      if salesforce_account_id.nil?
        salesforce_account_id = upsert_account_by_organisation_id(organisation)
      else
        upsert_account_by_salesforce_id(organisation, salesforce_account_id)    
      end

      Rails.logger.info(
        "Upserted an Account record in Salesforce with reference: #{salesforce_account_id}"
      )

      salesforce_account_id

    end

    # Upserts to an Account record in Salesforce using the organisation.id
    # Calling function should handle exceptions/retries
    #
    # @param [Organisation] organisation An instance of a Organisation object
    #
    # @return [String] salesforce_account_id A Salesforce Account Id for the Organisation
    def upsert_account_by_organisation_id(organisation)

      @client.upsert!(
        'Account',
        'Account_External_ID__c', 
        Name: organisation.name,
        Account_External_ID__c: organisation.id,
        BillingStreet: [organisation.line1, organisation.line2, organisation.line3].compact.join(', '),
        BillingCity: organisation.townCity,
        BillingState: organisation.county,
        BillingPostalCode: organisation.postcode,
        Company_Number__c: organisation.company_number,
        Charity_Number__c: organisation.charity_number,
        Charity_Number_NI__c: organisation.charity_number_ni,
        Organisation_Type__c: get_organisation_type_for_salesforce(organisation),
        Organisation_s_Mission_and_Objectives__c: convert_to_salesforce_mission_types(organisation.mission),
        Are_you_VAT_registered_picklist__c: translate_vat_registered_for_salesforce(organisation.vat_registered),
        VAT_number__c: organisation.vat_number,
        Organisation_s_Main_Purpose_Activities__c: organisation.main_purpose_and_activities,
        Number_Of_Board_members_or_Trustees__c: organisation.board_members_or_trustees, 
        Social_Media__c: organisation.social_media_info,
        Amount_spent_in_the_last_financial_year__c:	organisation.spend_in_last_financial_year,
        level_of_unrestricted_funds__c: organisation.unrestricted_funds
      )
    end

    # Upserts to an Account record in Salesforce using the salesforce Account Id
    # Calling function should handle exceptions/retries
    #
    # @param [Organisation] organisation An instance of a Organisation object
    # @param [String] salesforce_account_id A salesforce Account Id 
    #                                       for the User's organisation
    #
    # @return [String] salesforce_account_id A Salesforce Account Id for the Organisation
    def upsert_account_by_salesforce_id(organisation, salesforce_account_id)
      @client.upsert!(
        'Account',
        'Id', 
        Id: salesforce_account_id,
        Name: organisation.name,
        Account_External_ID__c: organisation.id,
        BillingStreet: [organisation.line1, organisation.line2, organisation.line3].compact.join(', '),
        BillingCity: organisation.townCity,
        BillingState: organisation.county,
        BillingPostalCode: organisation.postcode,
        Company_Number__c: organisation.company_number,
        Charity_Number__c: organisation.charity_number,
        Charity_Number_NI__c: organisation.charity_number_ni,
        Organisation_Type__c: get_organisation_type_for_salesforce(organisation),
        Organisation_s_Mission_and_Objectives__c: convert_to_salesforce_mission_types(organisation.mission),
        Are_you_VAT_registered_picklist__c: translate_vat_registered_for_salesforce(organisation.vat_registered),
        VAT_number__c: organisation.vat_number,
        Organisation_s_Main_Purpose_Activities__c: organisation.main_purpose_and_activities,
        Number_Of_Board_members_or_Trustees__c: organisation.board_members_or_trustees, 
        Social_Media__c: organisation.social_media_info,
        Amount_spent_in_the_last_financial_year__c:	organisation.spend_in_last_financial_year,
        level_of_unrestricted_funds__c: organisation.unrestricted_funds
      )
    end

    # Method to orchestrate upserting a Salesforce Contact record. 
    # Tries to find an existing Contact record in Salesforce first.
    # Then calls an appropriate upsert.  Upserts by Salesforce's
    # Contact Id if known.  Otherwise upserts by the User objects id.
    # Calling function should handle exceptions/retries
    #
    # @param [User] user An instance of a User object
    # @param [String] salesforce_account_id a salesforce organisation 
    #                                                   reference for the User's organisation
    #
    # @return [String] salesforce_contact_id A Salesforce contact Id for the Contact/User
    def upsert_contact_in_salesforce(user, salesforce_account_id)
      
      salesforce_contact_id = find_matching_contact_for_user(user)

      if salesforce_contact_id.nil?
        salesforce_contact_id = upsert_contact_by_user_id(user, salesforce_account_id)       
      else
        upsert_contact_by_salesforce_id(user, salesforce_contact_id, salesforce_account_id)    
      end

      Rails.logger.info(
        "Upserted a Contact record in Salesforce with Id: #{salesforce_contact_id}"
      )

      salesforce_contact_id

    end

    # Upserts to a Contact record in Salesforce using the Contact record's Id
    # Removes the FirstName, MiddleName, Suffix attributes, and 
    # populates LastName with the User.name value from Funding Frontend
    # Calling function should handle exceptions/retries
    #
    # @param [User] user An instance of a User object
    # @param [String] salesforce_contact_id The Contact record's Id
    # @param [String] salesforce_account_id A salesforce organisation 
    #                                                   reference for the User's organisation
    # @return [String] salesforce_contact_id A Salesforce contact Id for the Contact/User
    def upsert_contact_by_salesforce_id(user, salesforce_contact_id, salesforce_account_id) 
      salesforce_contact_id = @client.upsert!(
        'Contact',
        'Id',
        Id: salesforce_contact_id,
        Contact_External_ID__c: user.id,
        Salutation: '',
        FirstName: '',
        MiddleName: '',
        Suffix: '',
        LastName: user.name,
        Email: user.email,
        Email__c: user.email,
        Birthdate: user.date_of_birth,
        MailingStreet: [user.line1, user.line2, user.line3].compact.join(', '),
        MailingCity: user.townCity,
        MailingState: user.county,
        MailingPostalCode: user.postcode,
        Phone: user.phone_number,
        Other_communication_needs_for_contact__c: user.communication_needs,
        # Ensure we use a type of language preference known to Salesforce. If a different type, cover ourselves with both
        Language_Preference__c: (['english', 'welsh', 'both'].include? user.language_preference) ? user.language_preference : 'both',
        Agrees_To_User_Research__c: (user.agrees_to_user_research.present?) ? user.agrees_to_user_research : false,
        AccountId: salesforce_account_id
       ) 
    end 

    # Upserts to a Contact record in Salesforce using the User instance's id
    # Removes the Salutation, FirstName, MiddleName, Suffix attributes, and 
    # populates LastName with the User.name value from Funding Frontend
    # Calling function should handle exceptions/retries
    #
    # @param [User] user An instance of a User object
    # @param [String] salesforce_account_id A salesforce organisation 
    #                                                   reference for the User's organisation
    def upsert_contact_by_user_id(user, salesforce_account_id) 
      salesforce_contact_id = @client.upsert!(
        'Contact',
        'Contact_External_ID__c',
        Contact_External_ID__c: user.id,
        Salutation: '',
        FirstName: '',
        MiddleName: '',
        Suffix: '',
        LastName: user.name,
        Email: user.email,
        Email__c: user.email,
        Birthdate: user.date_of_birth,
        MailingStreet: [user.line1, user.line2, user.line3].compact.join(', '),
        MailingCity: user.townCity,
        MailingState: user.county,
        MailingPostalCode: user.postcode,
        Phone: user.phone_number,
        Other_communication_needs_for_contact__c: user.communication_needs,
        # Ensure we use a type of language preference known to Salesforce. If a different type, cover ourselves with both
        Language_Preference__c: (['english', 'welsh', 'both'].include? user.language_preference) ? user.language_preference : 'both',
        Agrees_To_User_Research__c: (user.agrees_to_user_research.present?) ? user.agrees_to_user_research : false,
        AccountId: salesforce_account_id
       ) 
    end 

    # Method to initialise a new Restforce client, called as part of object instantiation
    def initialise_client

      Rails.logger.info('Initialising Salesforce client')

      retry_number = 0
      
      begin

        @client = Restforce.new(
          username: Rails.configuration.x.salesforce.username,
          password: Rails.configuration.x.salesforce.password,
          security_token: Rails.configuration.x.salesforce.security_token,
          client_id: Rails.configuration.x.salesforce.client_id,
          client_secret: Rails.configuration.x.salesforce.client_secret,
          host: Rails.configuration.x.salesforce.host,
          api_version: '47.0'
        )

        Rails.logger.info('Finished initialising Salesforce client')

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt to initialise_client again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep(rand(0..max_sleep_seconds))

          retry

        else

          raise

        end

      end

    end

    # Uses an organisation's org_type to create the salesforce equivalent
    # Use 'Other' in event of non match to so applicant not impacted.
    #
    # @param [Organisation] instance of Organisation
    #
    # @return [String] A salesforce version of an org type
    def get_organisation_type_for_salesforce(organisation)

      formatted_org_type_value = case organisation.org_type
      when 'registered_charity'
        'Registered charity'
      when 'local_authority'
        'Local authority'
      when 'registered_company', 'community_interest_company'
        'Registered company or Community Interest Company (CIC)'
      when 'faith_based_organisation', 'church_organisation'
        'Faith based or church organisation'
      when 'community_group', 'voluntary_group'
        'Community of Voluntary group' # Typo is present in Salesforce API name
      when 'individual_private_owner_of_heritage'
        'Private owner of heritage'
      when 'other_public_sector_organisation'
        'Other public sector organisation'
      when 'other'
        'Other organisation type'
      else
        'Other organisation type'
      end

    end

    # Rails stores mission types as a comma delimited set of strings.
    # Salesforce requires these to be a semi-colon delimited string.
    #
    # @param [Array] an array of mission strings for an Organisation
    #
    # @return [Array] A re-mapped array of missions formatted for Salesforce
    def convert_to_salesforce_mission_types(mission)

      salesforce_mission_array = mission.map { |mission_type| translate_mission_type_for_salesforce(mission_type) }

      salesforce_mission_array.compact.join(';')
        
    end

    # Function to change an Organisation's mission type to a Salesforce equivalent
    #
    # @param [String] mission_type for an Organisation
    #
    # @return [String] the mission string re-formatted for Saleforce
    def translate_mission_type_for_salesforce(mission_type)

      formatted_mission_value = case mission_type
      when 'black_or_minority_ethnic_led'
        'Black or minority ethnic-led'
      when 'disability_led'
        'Disability-led'
      when 'lgbt_plus_led'
        'LGBT+-led'
      when 'female_led'
        'Female-led'
      when 'young_people_led'
        'Young people-led'
      when 'mainly_catholic_community_led'
        'Mainly led by people from Catholic communities'
      when 'mainly_protestant_community_led'
        'Mainly led by people from Protestant communities'
      end

    end

    # Method to translate a permission_type attribute into it's Salesforce
    # equivalent
    #
    # @param [String] permission_type A string representation of a permission
    #
    # @return [String] A string representation of the permission_type
    #                  that maps to the correct picklist value in Salesforce
    def translate_permission_type_for_salesforce(permission_type)

      permission_type = case permission_type
      when 'yes'
        'Yes I need permission'
      when 'no'
        'No I do not need permission'
      when 'x_not_sure'
        'Not sure if I need permission'
      else
        'Not sure if I need permission'
      end

    end

    # Method to translate a heritage_attracts_visitors attribute into it's
    # Salesforce equivalent
    #
    # @param [Boolean] heritage_attracts_visitors A Boolean representation of
    #                                             whether or not a project's
    #                                             heritage attracts visitors
    # @return [String] A string representation that maps to the correct
    #                  picklist value in Salesforce
    def translate_attracts_visitors_for_salesforce(heritage_attracts_visitors)

      attracts_visitors = case heritage_attracts_visitors
      when true
        'Yes'
      when false
        'No'
      else
        'N/A'
      end

    end

    # Method to translate vat_registered attribute into it's
    # Salesforce equivalent
    #
    # @param [Boolean] vat_registered A Boolean representation of
    #                                 whether an org is VAT registred
    # @return [String] A string representation that maps to the correct
    #                  picklist value in Salesforce
    def translate_vat_registered_for_salesforce(vat_registered)

      vat_registered_salesforce = case vat_registered
      when true
        'Yes'
      when false
        'No'
      else
        'N/A'
      end

    end

    # Method to translate an ownership_type attribute into it's Salesforce
    # equivalent
    #
    # @param [String] ownership_type A string representation of an ownership
    #                                type
    #
    # @return [String] A string representation of the ownership_type
    #                  that maps to the correct picklist value in Salesforce
    def translate_ownership_type_for_salesforce(ownership_type)

      capital_work_owner = case ownership_type
      when 'organisation'
        'Your organisation'
      when 'project_partner'
        'Project Partner'
      when 'neither'
        'Neither'
      when 'na'
        'N/A'
      end

    end

    # Method to translate formal heritage designations into their Salesforce
    # equivalent, in a format applicable to Salesforce (a semi-colon delimited
    # string)
    #
    # @param [ActiveRecord::Associations] formal_designations A collection of
    #                                       HeritageDesignation objects
    #
    # @return [String] A semi-colon delimited string of designations that map
    #                  to the correct picklist values in Salesforce
    def translate_formal_designations_for_salesforce(formal_designations)

      translated_designations = []

      formal_designations.each do |fd|

        designation = case fd.designation
        when 'accredited_museum_gallery_or_archive'
          'Accredited Museum, Gallery or Archive'
        when 'designated_or_significant_collection'
          'Designatd or Significant (Scotland) Collection'
        when 'dcms_funded_museum_gallery_or_archive'
          'DCMS funded Museum, Library, Gallery or Archive'
        when 'world_heritage_site'
          'World Heritage Site'
        when 'grade_1_or_a_listed_building'
          'Grade I or Grade A Listed Building'
        when 'grade_2_star_or_b_listed_building'
          'Grade II* or Grade B Listed Building'
        when 'grade_2_c_or_cs_listed_building'
          'Grade II, Grade C or Grade C(S) Listed Building'
        when 'local_list'
          'Local list'
        when 'scheduled_ancient_monument'
          'Scheduled Ancient Monument'
        when 'registered_historic_ship'
          'Registered Historic ship'
        when 'conservation_area'
          'Conservation Area'
        when 'registered_battlefield'
          'Registered Battlefield'
        when 'anob_or_nsa'
          'Area of AONB or NSA'
        when 'national_park'
          'National Park'
        when 'national_nature_reserve'
          'National Nature Reserve'
        when 'ramsar_site'
          'Ramsar Site'
        when 'rigs'
          'RIGS'
        when 'sac'
          'SAC or e-SAC'
        when 'spa'
          'Special protection Area (SPA)'
        when 'grade_1_listed_park_or_garden'
          'Grade I listed Park or Garden'
        when 'grade_2_star_listed_park_or_garden'
          'Grade II* listed Park or Garden'
        when 'grade_2_listed_park_or_garden'
          'Grade II listed Park or Garden'
        when 'protected_wreck_site'
          'Protected Wreck Site'
        when 'national_historic_organ_register'
          'National Historic Organ Register'
        when 'site_of_special_scientific_interest'
          'Site of Special Scientific Interest'
        when 'local_nature_reserve'
          'Local Nature Reserve'
        when 'other'
          'Other (please specify)'
        else
          'Other (please specify)'
        end

        translated_designations.append(designation)

      end

      translated_designations.compact.join(';')

    end

    # Method to determine whether the address for a funding application
    # and the address for an organisation match
    #
    # @param [FundingApplication] funding_application An instance of
    #                                                 FundingApplication
    # @param [Organisation] organisation An instance of Organisation
    #
    # @return [Boolean] A Boolean value to indicate whether the two
    #                   addresses match
    def do_project_and_organisation_addresses_match?(
      funding_application,
      organisation
    )

      application_address = [
        funding_application.open_medium.line1,
        funding_application.open_medium.line2,
        funding_application.open_medium.line3,
        funding_application.open_medium.townCity,
        funding_application.open_medium.county,
        funding_application.open_medium.postcode
      ]

      organisation_address = [
        organisation.line1,
        organisation.line2,
        organisation.line3,
        organisation.townCity,
        organisation.county,
        organisation.postcode
      ]

      application_address == organisation_address

    end

    # Method to return the right ownership_type_x_description attribute based
    # on which ownership_type is present for an OpenMedium object
    #
    # @param [OpenMedium] open_medium An instance of an OpenMedium object
    #
    # @return [String] A description of a capital work ownership type
    def get_relevant_ownership_type_description(open_medium)

      if open_medium.ownership_type_org_description.present?
        capital_work_details = open_medium.ownership_type_org_description
      elsif open_medium.ownership_type_pp_description.present?
        capital_work_details = open_medium.ownership_type_pp_description
      elsif open_medium.ownership_type_neither_description.present?
        capital_work_details = open_medium.ownership_type_neither_description
      end

    end

    # Method to translate a cost_type attribute into it's Salesforce equivalent
    #
    # @param [String] cost_type A string representation of a cost type/heading
    #
    # @return [String] A string representation of the cost_type that maps to
    #                  the correct picklist value in Salesforce
    def translate_cost_type_for_salesforce(cost_type)

      translated_cost_type = case cost_type
      when 'new_staff'
        'New staff'
      when 'professional_fees'
        'Professional fees'
      when 'recruitment'
        'Recruitment'
      when 'purchase_price_of_heritage_items'
        'Purchase price of heritage items'
      when 'repair_and_conservation_work'
        'Repair and conservation work'
      when 'event_costs'
        'Event Costs'
      when 'digital_outputs'
        'Digital outputs'
      when 'equipment_and_materials_including_learning_materials'
        'Equipment and materials including learning materials'
      when 'training_for_staff'
        'Training for staff'
      when 'training_for_volunteers'
        'Training for volunteers'
      when 'travel_for_staff'
        'Travel for staff'
      when 'travel_for_volunteers'
        'Travel for volunteers'
      when 'expenses_for_staff'
        'Expenses for staff'
      when 'expenses_for_volunteers'
        'Expenses for volunteers'
      when 'other'
        'Other'
      when 'publicity_and_promotion'
        'Publicity and promotion'
      when 'evaluation'
        'Evaluation'
      when 'contingency'
        'Contingency'
      when 'new_build_work'
        'New build work'
      when 'community_grants'
        'Community grants'
      when 'full_cost_recovery'
        'Full Cost Recovery'
      when 'inflation'
        'Inflation'
      else
        'Other'
      end

    end

    # Method to translate a secured attribute into it's Salesforce equivalent
    #
    # @return [String] A string representation of the secured attribute that
    #                  maps to the correct picklist value in Salesforce
    def translate_secured_for_salesforce(secured)

      secured_value = case secured
      when 'yes_with_evidence'
        'Yes - I can provide evidence'
      when 'no'
        'No'
      when 'x_not_sure'
        'Not Sure'
      when 'yes_no_evidence_yet'
        'Yes - but I do not have evidence yet'
      else
        'Not Sure'
      end

    end

    # Method to retrieve an expression of interest's reference from Salesforce
    #
    # @param [PaExpressionOfInterest] expression_of_interest An instance of PaExpressionOfInterest
    #
    # @return [String] expression_of_interest.Name A string representing the name/reference of 
    # the expression of interest
    def get_salesforce_expression_of_interest_reference(expression_of_interest)

      retry_number = 0

      begin

        salesforce_expression_of_interest = @client.find(
          'Expression_Of_Interest__c',
          expression_of_interest.id,
          'Expression_Of_Interest_external_ID__c'
        )

        salesforce_expression_of_interest.Name

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
             Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error retrieving salesforce_expression_of_interest.Name " \
          "for expression of interest id #{expression_of_interest.id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt get_salesforce_expression_of_interest_reference again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method to retrieve an project enquiry's reference from Salesforce
    #
    # @param [PaProjectEnquiry] project_enquiry An instance of PaProjectEnquiry
    #
    # @return [String] project_enquiry.Name The salesforce reference of the project enquiry
    def get_salesforce_salesforce_project_enquiry_reference(project_enquiry)
      
      retry_number = 0

      begin

        salesforce_project_enquiry = @client.find(
          'Project_Enquiry__c',
          project_enquiry.id,
          'Project_Enquiry_external_ID__c'
        )

        salesforce_project_enquiry.Name

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
             Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error("Error retrieving salesforce_project_enquiry.Name " \
          "for project enquiry id #{project_enquiry.id}")

        # Raise and allow global exception handler to catch
        raise

      rescue Timeout::Error, Faraday::ClientError => e

        if retry_number < MAX_RETRIES

          retry_number += 1

          max_sleep_seconds = Float(2 ** retry_number)

          Rails.logger.info(
            "Will attempt get_salesforce_salesforce_project_enquiry_reference again, retry number #{retry_number} " \
            "after a sleeping for up to #{max_sleep_seconds} seconds"
          )

          sleep rand(0..max_sleep_seconds)

          retry

        else

          raise

        end

      end

    end

    # Method check Salesforce for existing Contact records for the passed User instance
    # Firstly checks if a Contact record exists with an external ID matching the user.id
    # If no match found, then tries to find a Contact record with a matching email
    # A Salesforce Id for the Contact record is returned if a match is made.  Otherwise nil.
    # Calling function should handle exceptions/retries
    #
    # @param [User] user An instance of User which is the current user
    #
    # @return [String] contact_salesforce_id A string representing Salesforce Id 
    #                                        for the Contact record, or nil
    def find_matching_contact_for_user(user)
      
      begin

        contact_salesforce_id =  @client.find(
          'Contact',
          user.id,
          'Contact_External_ID__c'
        ).Id

      rescue Restforce::NotFoundError
        Rails.logger.info("Unable to find contact with external id #{user.id} " \
          "will attempt to find contact using a name and Email match")  
      end
      
      unless contact_salesforce_id 

        contact_collection_from_salesforce = 
          @client.query_all("select Id from Contact where Email = '#{user.email}'")

        contact_salesforce_id = contact_collection_from_salesforce&.first&.Id

      end

      Rails.logger.info("Unable to find contact with matching name and email for "\
        "user id #{user.id}") if contact_salesforce_id.nil?
      
      contact_salesforce_id

    end

    # Method check Salesforce for existing Account (Organisation) records for the passed 
    # Organisation instance.
    # Firstly checks if an Account record exists with an external ID matching the organisation.id
    # If no match found, then tries to find a Account record with a matching 
    # organisation name and postcode combination.  
    # A Salesforce Id for the Account record is returned if a match is made.  Otherwise nil.
    # Calling function should handle exceptions/retries.
    #
    # @param [Organisation] organisation An instance of Organisation which is the 
    # organisation for the current user.
    #
    # @return [String] Account_salesforce_id A string representing Salesforce Id 
    #                                        for the Account record, or nil
    def find_matching_account_for_organisation(organisation)
      
      begin

        account_salesforce_id =  @client.find(
          'Account',
          organisation.id,
          'Account_External_ID__c'
        ).Id

      rescue Restforce::NotFoundError
        Rails.logger.info("Unable to find account with external id #{organisation.id} " \
          "will attempt to find account using a name and postcode match")  
      end
      
      unless account_salesforce_id 
        
        # Ruby unusual in its approach to escaping.  This is the regex approach other devs adopt: 
        # https://github.com/restforce/restforce/issues/314
        escaped_org_name = organisation.name.gsub(/[']/,"\\\\'")
    
        account_collection_from_salesforce = 
          @client.query_all("select Id from Account where name = '#{escaped_org_name}' and BillingPostalCode = '#{organisation.postcode}'")

        account_salesforce_id = account_collection_from_salesforce&.first&.Id

      end

      Rails.logger.info("Unable to find account with matching name and postcode for "\
        "organisation id #{organisation.id}") if account_salesforce_id.nil?
      
      account_salesforce_id

    end

    # Method check Salesforce for a correct RecordType Id
    # A Salesforce Id for the RecordType is returned if a match is made. 
    # Otherwise a not found exception is raised.
    #
    # exceptions and retries should be handled in calling function.
    #
    # @param [String] developer_name An salesforce Developername for a RecordType
    # @param [String] object_type An salesforce SobjectType for a RecordType
    #
    # @return [String] record_type_id&.first&.Id The RecordType.Id found
    def get_salesforce_record_type_id(developer_name, object_type)    

      record_type_id = 
        @client.query_all("select Id, SObjectType from RecordType where DeveloperName = '#{developer_name}' " \
                          "and SObjectType = '#{object_type}'")

      if record_type_id.length != 1

        error_msg = "No RecordType found for DeveloperName: #{developer_name} and SObjectType: #{developer_name}"

        Rails.logger.error(error_msg)

        raise Restforce::NotFoundError.new(error_msg, { status: 500 } )

      end

      record_type_id&.first&.Id

    end

    # Method to upsert a Bank Account record in Salesforce
    # Sends the decrypted values
    # The external id is the account number and sort code concatenated
    # which is unique across all banks for the UK.
    #
    # Retries handled by calling function
    #
    # @param [FundingApplication] funding_application An FundingApplication instance
    #
    # @return [String] salesforce_bank_account_id The Salesforce reference for the record
    def upsert_bank_account_details(funding_application)

      begin

        salesforce_account_id = funding_application.organisation.salesforce_account_id

        salesforce_bank_account_id = @client.upsert!(
          'Bank_Account__c',
          'Account_Number_Sort_Code__c',
          Account_Name__c: funding_application.payment_details.decrypt_account_name,
          Account_Number__c: funding_application.payment_details.decrypt_account_number,
          Building_Society_Roll_Numbe__c: funding_application.payment_details.decrypt_building_society_roll_number, 
          Organisation__c: salesforce_account_id,
          Sort_Code__c: funding_application.payment_details.decrypt_sort_code,
          Account_Number_Sort_Code__c: funding_application.payment_details.decrypt_account_number \
            + funding_application.payment_details.decrypt_sort_code
        )

        Rails.logger.info(
          'Created a bank account record in Salesforce with ' \
          "reference: #{salesforce_bank_account_id}"
        )

        salesforce_bank_account_id

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
            Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error(
          'Error creating a bank account record in Salesforce using funding application  ' \
          "#{funding_application.id}"
        )

        # Raise and allow global exception handler to catch
        raise

      end

    end
    
    # Method to upsert a Form record in Salesforce with fields
    # that relate to a payment request
    # The external id used if the payment_request.id
    #
    # Retries handled by calling function
    #
    # @param [FundingApplication] funding_application An FundingApplication instance
    # @param [PaymentRequest] payment_request A PaymentRequest instance
    #
    # @return [String] salesforce_payment_request_id The Salesforce reference for the record
    def upsert_payment_request_details(funding_application, payment_request)

      begin
        
        salesforce_payment_request_id = @client.upsert!(
          'Forms__c',
          'Payment_Request_External_ID__c',
          Case__c: funding_application.salesforce_case_id,
          Payment_Request_External_ID__c: payment_request.id,
          Payment_Reference_number__c: funding_application.payment_details.decrypt_payment_reference,
          Payment_Request_From_Applicant__c: payment_request.amount_requested 
        )

        Rails.logger.info(
          'Created a payment request record in Salesforce with ' \
          "reference: #{salesforce_payment_request_id}"
        )

        salesforce_payment_request_id

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
            Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error(
          'Error creating a payment request record in Salesforce using funding application id ' \
          "#{funding_application.id} and payment request id #{payment_request.id}"
        )

        # Raise and allow global exception handler to catch
        raise

      end

    end

    # Method to upsert a Form Bank Account Junction record in Salesforce 
    # Used by Salesforce to link Forms__c and BankAccount__c records
    # Specifies an external id to make the request idempotent, but it is
    # the two parameters concatenated.
    #
    # Retries handled by calling function
    #
    # @param [String] salesforce_bank_account_id a record id for BankAccount__c
    # @param [String] salesforce_payment_request_id a record id for Forms__c
    #
    # @return [String] salesforce_payment_request_id The Salesforce reference for the record
    def upsert_bank_account_payment_request_junction(salesforce_bank_account_id, salesforce_payment_request_id)

      begin

        salesforce_form_bank_account_id = @client.upsert!(
          'Form_Bank_Account__c',
          'Forms_Bank_Account_External_Id__c',
          Bank_Account__c: salesforce_bank_account_id,
          Forms__c: salesforce_payment_request_id,
          Forms_Bank_Account_External_Id__c: salesforce_bank_account_id + salesforce_payment_request_id,
        )

        Rails.logger.info(
          'Created a form bank account junction record in Salesforce with ' \
          "reference: #{salesforce_form_bank_account_id}"
        )

        salesforce_form_bank_account_id

      rescue Restforce::MatchesMultipleError, Restforce::UnauthorizedError,
            Restforce::EntityTooLargeError, Restforce::ResponseError => e

        Rails.logger.error(
          'Error creating a form bank account junction record in Salesforce using ' \
            "salesforce_bank_account_id: #{salesforce_bank_account_id} and " \
              "salesforce_payment_request_id: #{salesforce_payment_request_id}"
        )

        # Raise and allow global exception handler to catch
        raise

      end

    end
  end
end
