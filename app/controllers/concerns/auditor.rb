module Auditor
  extend ActiveSupport::Concern

  # Updates the audits table
  # Calling function should include the audit call in a transaction
  # with the associated record change.
  #
  # @param [User] audit_user The user that is subject of audit
  # @param [ApplicationRecord] audit_record
  #           The Application record that is the subject of audit
  # @param [Integer] action Enumerated type. See audit_action in Audit.rb
  # @param [Hash] changes_hash Changes made to the record
  # @param [String] request_id  A uuid for the request. When the value is not
  #                             provided, a uuid is set.  This is fine when one
  #                             record is audited.  But pass a request_id to
  #                             this function from a controller auditing more
  #                             than one model change as part of one request.
  # @param [Date] redact_date Date for redaction.  Default is 6yrs from now
  # @param [Boolean] action_successful. Set to false if the action was
  #       asynchronous and failed.  Default true as most actions synchronous
  def create_audit_row(
    audit_user,
    audit_record,
    action,
    changes_hash,
    request_id = SecureRandom.uuid,
    redact_date = 6.years.from_now,
    action_successful = true
  )

    audit_row = Audit.new

    audit_row.user_id = audit_user.id
    audit_row.user_name = audit_user&.name
    audit_row.user_email = audit_user&.email
    audit_row.user_role = User.roles[audit_user&.role]

    audit_row.record_type = audit_record.class.name
    audit_row.record_id = audit_record.id

    audit_row.action = action
    audit_row.action_successful = action_successful

    audit_row.record_changes = changes_hash

    audit_row.request_id = request_id

    audit_row.redact_date = redact_date

    begin

      audit_row.save!

      Rails.logger.info("Audit id: #{audit_row.id} " \
        "saved for record id: " \
          "#{audit_row.record_id} with record type: " \
            "#{audit_row.record_type}")

    rescue Exception => e

      Rails.logger.error("Audit row ERROR for record id: "\
        "#{audit_row.record_id} with record type: " \
          "#{audit_row.record_type}.  Error message: " \
            "#{e.message}")

      raise

    end

  end

end
