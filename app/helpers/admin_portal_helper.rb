module AdminPortalHelper
  include SalesforceApi
  include Auditor

# main_contact_apps structure:
#
# [{
# 	id => "a guid",
# 	ref_no => "NS-22-00025",
# 	type => 1,
# 	title => "3-10K project"
#   salesforce_id => "a string"
# }, {
# 	id => "a guid",
# 	ref_no => "NM-22-00004",
# 	type => 2,
# 	title => "10-250K project"
#   salesforce_id => "a string"
# },
# {
# 	id => "a guid",
# 	ref_no => "NL-22-1234",
# 	type => 3,
# 	title => "Large application"
#   salesforce_id => "a string"
# }, {
# 	id => "a guid",
# 	ref_no => "PEF ref no",
# 	type => 4,
# 	title => "My PEF"
#   salesforce_id => "a string"
# {
# 	id => "a guid",
# 	ref_no => "EOI ref no",
# 	type => 5,
# 	title => "My EOI"
#   salesforce_id => "a string"
# }]

  SMALL = 1
  MEDIUM  = 2
  LARGE = 3
  PEF = 4
  EOI = 5
  UNKNOWN = 6

  # Creates an array of hashes for the applications and
  # pre-applications belonging to a main applicant.
  # See top of file for structure.
  #
  # @param [String] user_id Id for the main contact
  # @param [String] org_id Id for the main contact's org
  # @return [Array] main_contact_apps Collection of main contact's
  #                                               apps and pre-apps
  def get_main_contact_apps(org_id, user_id)

    funding_applications =
      FundingApplication.where(
        organisation_id: org_id
      )

    pre_applications =
      PreApplication.where(
        organisation_id: org_id,
        user_id: user_id
      )

    main_contact_apps = [] # applications and pre-applications

    funding_applications.each do |fa|

      if fa.open_medium.present?
        title = fa.open_medium.project_title
        type = MEDIUM
      end

      if fa.project.present?
        title = fa.project.project_title
        type = SMALL
      end

      if fa.dev_to_100k? ||
        fa.dev_over_100k? ||
          fa.del_250k_to_5mm? ||
            fa.migrated_large_delivery?

        type = LARGE
        salesforce_api_client= SalesforceApiClient.new
        title =  salesforce_api_client
          .get_project_title(fa.salesforce_case_id)
            .Project_Title__c

      end

      title = title.present? ? title : 'Untitled application'
      ref_no = fa.project_reference_number.present? ? \
        fa.project_reference_number : 'NOT SUBMITTED'
      id = fa.id
      salesforce_id = fa.salesforce_case_id

      main_contact_apps.push(
        {
          id: id,
          ref_no: ref_no,
          type: type,
          title: title,
          salesforce_id: salesforce_id
        }
      )

    end

    pre_applications.each do |pa|

      if pa.pa_project_enquiry.present?
        title = pa.pa_project_enquiry.working_title
        type = PEF
        salesforce_id = pa.pa_project_enquiry.salesforce_project_enquiry_id
        ref_no = pa.pa_project_enquiry.salesforce_pef_reference.present? \
          ? pa.pa_project_enquiry.salesforce_pef_reference : 'NOT SUBMITTED'
      end

      if pa.pa_expression_of_interest.present?
        title = pa.pa_expression_of_interest.working_title
        type = EOI
        salesforce_id =
          pa.pa_expression_of_interest.salesforce_expression_of_interest_id
        ref_no = pa.pa_expression_of_interest.salesforce_eoi_reference.present? \
          ? pa.pa_expression_of_interest.salesforce_eoi_reference : 'NOT SUBMITTED'
      end

      title = title.present? ? title : 'Untitled pre-application'
      id = pa.id

      main_contact_apps.push(
        {
          id: id,
          ref_no: ref_no,
          type: type,
          title: title,
          salesforce_id: salesforce_id
          }
        )

    end

    main_contact_apps

  end

  # Uses chosen_app_hash to determine the kind of application
  # that is being moved, then uses the appropriate method
  # for the move, passing the required information.
  #
  # @param [Hash] chosen_app_hash App that we are moving: example
  #         {:id=>"", :ref_no=>"", :type=>1, :title=>"", salesforce_id => ""}
  # @param [Integer] new_contact_id FFE id for new contact
  # @param [String] new_org_id FFE GUID for new organisation
  def move_app_to_new_user(chosen_app_hash, new_contact_id, new_org_id)

    case chosen_app_hash[:type]
    when SMALL
      move_3_to_10k(chosen_app_hash, new_contact_id, new_org_id)
    when MEDIUM
      move_10_to_250k(chosen_app_hash, new_contact_id, new_org_id)
    when LARGE
      move_large(chosen_app_hash, new_org_id)
    when PEF
      move_pre_application(chosen_app_hash, new_contact_id, new_org_id)
    when EOI
      move_pre_application(chosen_app_hash, new_contact_id, new_org_id)
    when UNKNOWN
      Rails.logger.info("Tried to move unknown application to user " \
        "#{new_contact_id}.  This application may have been moved already. " \
          "Nothing has been done.")
    end

  end

  # Moves a 3-10K project to a new user
  # Amends projects and funding_applications rows
  # Writes audit row of changes
  # Rollback on validation and logs reason, support team will
  # get a Rails error, but this will show on Sentry.
  #
  # @param [Hash] chosen_app_hash App that we are moving: example
  #         {:id=>"", :ref_no=>"", :type=>1, :title=>"", salesforce_id => ""}
  # @param [Integer] new_contact_id FFE id for new contact
  # @param [String] new_org_id FFE GUID for new organisation
  def move_3_to_10k(chosen_app_hash, new_contact_id, new_org_id)

    Rails.logger.info("Started moving 3-10K application with id: " \
      "#{chosen_app_hash[:id]} to user " \
        "#{new_contact_id} who uses organisation id: " \
          "#{new_org_id}"
    )

    project = Project.find_by(funding_application_id: chosen_app_hash[:id])
    project.user_id = new_contact_id

    funding_application = FundingApplication.find(chosen_app_hash[:id])
    funding_application.organisation_id = new_org_id

    FundingApplication.transaction do

      # Two audits done here, so create and pass common request id
      transaction_request_id = SecureRandom.uuid

      create_audit_row(
        current_user,
        funding_application,
        Audit.audit_actions['admin_application_change'],
        funding_application.changes,
        transaction_request_id
      ) if funding_application.changed?

      create_audit_row(
        current_user,
        project,
        Audit.audit_actions['admin_application_change'],
        project.changes,
        transaction_request_id
      ) if project.changed?

      funding_application.save!
      project.save!

    rescue ActiveRecord::RecordInvalid => exception
      Rails.logger.error(
        "move_3_to_10k failed to move funding application " \
          "#{chosen_app_hash[:id]} to new user id " \
            "#{new_contact_id} exception: #{exception}"
      )
      raise
    end

    Rails.logger.info("Successfully moved 3-10K application with id: " \
      "#{funding_application.id} to user " \
        "#{project.user_id} who uses organisation id: " \
          "#{funding_application.organisation_id}"
    )

  end

  # Moves a 10-250K project to a new user
  # Amends gp_open_medium and funding_applications rows
  # Writes audit row of changes
  # Rollback on validation and logs reason, support team will
  # get a Rails error, but this will show on Sentry.
  #
  # @param [Hash] chosen_app_hash App that we are moving: example
  #         {:id=>"", :ref_no=>"", :type=>1, :title=>"", salesforce_id => ""}
  # @param [Integer] new_contact_id FFE id for new contact
  # @param [String] new_org_id FFE GUID for new organisation
  def move_10_to_250k(chosen_app_hash, new_contact_id, new_org_id)

    Rails.logger.info("Started moving 10-250K application with id: " \
      "#{chosen_app_hash[:id]} to user " \
        "#{new_contact_id} who uses organisation id: " \
          "#{new_org_id}"
    )

    medium = OpenMedium.find_by(funding_application_id: chosen_app_hash[:id])
    medium.user_id = new_contact_id

    funding_application = FundingApplication.find(chosen_app_hash[:id])
    funding_application.organisation_id = new_org_id

    FundingApplication.transaction do

      # Two audits done here, so create and pass common request id
      transaction_request_id = SecureRandom.uuid

      create_audit_row(
        current_user,
        funding_application,
        Audit.audit_actions['admin_application_change'],
        funding_application.changes,
        transaction_request_id
      ) if funding_application.changed?

      create_audit_row(
        current_user,
        medium,
        Audit.audit_actions['admin_application_change'],
        medium.changes,
        transaction_request_id
      ) if medium.changed?

      funding_application.save!
      medium.save!

    rescue ActiveRecord::RecordInvalid => exception
      Rails.logger.error(
        "move_10_to_250k failed to move funding application " \
          "#{chosen_app_hash[:id]} to new user id " \
            "#{new_contact_id} exception: #{exception}"
      )
      raise
    end

    Rails.logger.info("Successfully moved 10-250K application with id: " \
      "#{funding_application.id} to user " \
        "#{medium.user_id} who uses organisation id: " \
          "#{funding_application.organisation_id}"
    )

  end

  # Moves a dev_to_100k, dev_over_100k, del_250k_to_5mm or
  # migrated_large_delivery project to a new user.
  # Amends gp_open_medium and funding_applications rows
  # Writes audit row of changes
  # Rollback on validation and logs reason, support team will
  # get a Rails error, but this will show on Sentry.
  #
  # @param [Hash] chosen_app_hash App that we are moving: example
  #         {:id=>"", :ref_no=>"", :type=>1, :title=>"", salesforce_id => ""}
  # @param [String] new_org_id FFE GUID for new organisation
  def move_large(chosen_app_hash, new_org_id)

    Rails.logger.info("Started moving a large application with id: " \
      "#{chosen_app_hash[:id]} to organisation id: " \
          "#{new_org_id}"
    )

    funding_application = FundingApplication.find(chosen_app_hash[:id])
    funding_application.organisation_id = new_org_id

    FundingApplication.transaction do

      create_audit_row(
        current_user,
        funding_application,
        Audit.audit_actions['admin_application_change'],
        funding_application.changes
      ) if funding_application.changed?

      funding_application.save!

    rescue ActiveRecord::RecordInvalid => exception
      Rails.logger.error(
        "move_large failed to move funding application " \
          "#{chosen_app_hash[:id]} to new org id " \
            "#{new_org_id} exception: #{exception}"
      )
      raise
    end

    Rails.logger.info("Successfully moved large application with id: " \
      "#{funding_application.id} to organisation id: " \
          "#{funding_application.organisation_id}"
    )

  end

  # Moves a pre_application to a new user
  # Amends pre_applications rows
  # Writes audit row of changes
  # logs reason for any save issues, support team will
  # get a Rails error, but this will show on Sentry.
  #
  # @param [Hash] chosen_app_hash App that we are moving: example
  #         {:id=>"", :ref_no=>"", :type=>1, :title=>"", salesforce_id => ""}
  # @param [Integer] new_contact_id FFE id for new contact
  # @param [String] new_org_id FFE GUID for new organisation
  def move_pre_application(chosen_app_hash, new_contact_id, new_org_id)

    Rails.logger.info("Started moving pre_application with id: " \
      "#{chosen_app_hash[:id]} to user " \
        "#{new_contact_id} who uses organisation id: " \
          "#{new_org_id}"
    )

    pre_app = PreApplication.find(chosen_app_hash[:id])
    pre_app.user_id = new_contact_id
    pre_app.organisation_id = new_org_id

    PreApplication.transaction do

      create_audit_row(
        current_user,
        pre_app,
        Audit.audit_actions['admin_application_change'],
        pre_app.changes
      ) if pre_app.changed?

      pre_app.save!

    rescue ActiveRecord::RecordInvalid => exception
      Rails.logger.error(
        "move_pre_application failed to move pre-application " \
          "#{chosen_app_hash[:id]} to new user id " \
            "#{new_contact_id} exception: #{exception}"
      )
      raise
    end

    Rails.logger.info("Successfully moved pre_application with id: " \
      "#{pre_app.id} to user " \
        "#{pre_app.user_id} who uses organisation id: " \
          "#{pre_app.organisation_id}"
    )

  end

  # returns the chosen app hash from the complete list
  # (structure at top of this file) from its application id
  #
  # @param [Array] main_contact_apps Array of hashes
  # @param [String] app_id FFE GUID for an app or pre-app
  def get_chosen_app_hash(main_contact_apps, app_id)

    main_contact_apps.each do |app|

      return app if app[:id] == app_id

    end

    return {
            id: "Application not found",
            ref_no:  "Application not found",
            type: UNKNOWN,
            title: "Application not found",
            salesforce_id: "Application not found"
          }

  end

end
