module OrganisationHelper
  include OrganisationSalesforceApi

  MAX_RETRIES = 3

  # Checks for the presence of mandatory organisation parameters,
  # returning false if any are not present and true if all are
  # present
  #
  # @param [Organisation] organisation An instance of Organisation
  def complete_organisation_details?(organisation)

    [
        organisation.name.present?,
        organisation.line1.present?,
        organisation.townCity.present?,
        organisation.county.present?,
        organisation.postcode.present?,
        organisation.org_type.present?
    ].all?

  end

  def complete_organisation_details_for_pre_application?(organisation)

    [
        organisation.name.present?,
        organisation.line1.present?,
        organisation.townCity.present?,
        organisation.county.present?,
        organisation.postcode.present?,
        organisation.org_type.present?
    ].all?

  end

  # Checks for the presence of an organisation associated to a user
  # and creates one if none exists
  #
  # @param [User] user An instance of User
  def create_organisation_if_none_exists(user)

    # rubocop:disable Style/GuardClause
    unless user.organisations.any?

      logger.info "No organisation found for user ID: #{user.id}"

      create_organisation(user)

    else

      user.organisations.first

    end
    # rubocop:enable Style/GuardClause

  end

  # Creates an organisation and links this to the current_user
  #
  # @param [User] user An instance of User
  def create_organisation(user)

    organisation = user.organisations.create

    logger.info "Successfully created organisation ID: #{organisation.id}"

    organisation

  end

  # Method to retrieve and update latest org details from salesforce
  # aligning FFE with any salesforce changes.
  #
  # We don't update organisation details that are asked at the start
  # of the medium grant journey.  This is because these questions are
  # always asked as part of a medium grant and so a sync is not
  # necessary.  When we had these questions included, they were being
  # erroneously updated from Salesforce, wiping answers.
  #
  # @param [Organisation] organisation The organisation to update.
  #
  def update_existing_organisation_from_salesforce_details(organisation)
    retry_number = 0

    begin

      client = OrganisationSalesforceApi.new
      sf_details = client.retrieve_existing_sf_org_details(organisation.salesforce_account_id)

      lines_array = ['', '', '']

      # BillingStreet nil when Account created with no address
      unless sf_details.BillingStreet.nil?
        lines_array = sf_details.BillingStreet.split(/\s*,\s*/)
      end

      organisation.name = sf_details.Name
      organisation.line1 = lines_array[0]
      organisation.line2 = lines_array[1]
      organisation.line3 = lines_array[2]

      organisation.townCity = sf_details.BillingCity
      organisation.county = sf_details.BillingState
      organisation.postcode = sf_details.BillingPostalCode
      organisation.company_number = sf_details.Company_Number__c
      organisation.charity_number = sf_details.Charity_Number__c
      organisation.charity_number_ni = sf_details.Charity_Number_NI__c
      organisation.mission = convert_mission_objective_type(sf_details.Organisation_s_Mission_and_Objectives__c)

      #Currently not used as org_types in SF and FFE do not align
      # organisation.org_type = convert_org_type(sf_details.Organisation_Type__c)

      organisation.save!

      update_salesforce_changes_checks(organisation)

      Rails.logger.info("Latest organisation details for id: " \
        "#{organisation.id} populated from salesforce_account_id: " \
          "#{organisation.salesforce_account_id}")

    rescue StandardError => e

      if retry_number < MAX_RETRIES
        
        retry_number +=1

        max_sleep_seconds = Float(2 ** retry_number)

        Rails.logger.info(
          "Will attempt update organisation details from salesforce " \
            "again, retry number #{retry_number} " \
              "after a sleeping for up to #{max_sleep_seconds} seconds"
        )

        sleep rand(0..max_sleep_seconds)

        retry

      else

        Rails.logger.error("Latest organisation details for id: " \
          "#{organisation.id} populated from salesforce_account_id: " \
            "#{organisation.salesforce_account_id} failed owing to " \
              "error: #{e.message}"
        )

        raise

      end
    end
  end

  # Updates the salesforce_changes_check table if
  # updates have been pulled from Salesforce
  #
  # This function could be moved into SalesforceChangesCheck
  # model, if other models end up using this.
  #
  # @param [Organisation] organisation
  def update_salesforce_changes_checks(organisation)

    existing_row =
      SalesforceChangesCheck.find_by(record_id: organisation.id)

    if existing_row.present?

      existing_row.update!(
        time_salesforce_checked: DateTime.now
      )

    else

      SalesforceChangesCheck.create!(
        record_id: organisation.id,
        record_type: organisation.class,
        time_salesforce_checked: DateTime.now
      )

    end

  end

  # True if updates have been pulled from Salesforce today.
  #
  # This function could be moved into SalesforceChangesCheck
  # model, if other models end up using this.
  #
  # @param [Organisation] organisation
  def salesforce_checked_today?(organisation)

    record =
      SalesforceChangesCheck.find_by(record_id: organisation.id)

    record.present? ? record.updated_at.today? : false

  end

  # Method to convert salesforce VAT_registered type to FFE type
  #
  # @param [String] vat_registered The salesforce string denoting
  #                                 VAT_Register type.
  #
  #  @return [Boolean] boolean Value of VAT_Registered. Or nil if
  #                            'N/A' or if there is no match, such
  #                             as when SF set to 'None'
  def convert_vat_registered(vat_registered)

    case vat_registered
    when "Yes"
      return true
    when "No"
      return false
    when "N/A"
      return nil
    end
  end

  # Currently not used as org_types in SF and FFE do not align
  # This will be enhanced and used in future work
  def convert_org_type(org_type_string)

    case org_type_string
    when "Registered charity"
      return "registered_charity"
    when "Local authority'"
      return "local_authority"
    when "Registered company or Community Interest Company (CIC)" 
      return "registered_company"
    # when "community interest company"
    #   return "community_interest_company"
    when "Faith based or church organisation"
      return "faith_based_organisation"
    # when "church organisation"
    #   return "church_organisation"
    when "Community of Voluntary group"
      return "community_group"
    # when " voluntary group"
    #   return "voluntary_group"
    when "Private owner of heritage"
      return "individual_private_owner_of_heritage"
    when "Other organisation type"
      return "other"
    when "Other public sector organisation"
      return "other_public_sector_organisation"
    end
  end

  # Method to convert salesforce mission/objective type to FFE type
  # aligning FFE with any salesforce changes.
  #
  # @param [String] mission_objective_type A string containing a collection of
  #                              mission/objectives, in the salesforce format.
  #
  # @return [Array<string> ] missions_list String array of FFE mission/objectives  
  #                                         to add against organisation. 
  def convert_mission_objective_type(mission_objective_type)

    missions_list = []

    if mission_objective_type.present?

      mission_objective_type = mission_objective_type.split(";")

      mission_objective_type.each do | mission |
        case mission
        when 'Black or minority ethnic-led'
          missions_list.append('black_or_minority_ethnic_led')
        when 'Disability-led'
          missions_list.append('disability_led')
        when 'LGBT+-led'
          missions_list.append('lgbt_plus_led')
        when 'Female-led'
          missions_list.append('female_led')
        when 'Young people-led'
          missions_list.append('young_people_led')
        when 'Mainly led by people from Catholic communities'
          missions_list.append('mainly_catholic_community_led')
        when 'Mainly led by people from Protestant communities'
          missions_list.append('mainly_protestant_community_led')
        end
      end

    end

    missions_list

  end

end
