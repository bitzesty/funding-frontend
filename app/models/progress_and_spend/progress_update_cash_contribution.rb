# Class responsible for validating and storing updates provided
# about Cash Contributions so that they can be sent to Salesforce
# as part of an arrears payment request.
#
# An object is only created from this class when an applicant
# selects a cash contribution to update.  This decision is
# stored using the "selected_for_update" key nested in the
# ["cash_contribution"]["records"] part of
# the answers_json field of the progress_updates table.
#
# As such, the ["cash_contribution"]["records"] key should be
# checked to see what ProgressUpdateCashContribution objects
# were "selected_for_update" before sending information to Salesforce, as
# an applicant can change their minds on what cash_contribution they update
# but no ProgressUpdateCashContribution objects (or pg rows)
# are destroyed once created.

class ProgressUpdateCashContribution < ApplicationRecord
  include GenericValidator

  self.table_name = 'prgrss_updts_csh_cntrbtns'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  attr_accessor :date_day
  attr_accessor :date_month
  attr_accessor :date_year

  attr_accessor :validate_reason_amount_expected_not_received
  attr_accessor :validate_reason_amount_expected
  attr_accessor :validate_date_day_month_year
  attr_accessor :validate_received_amount_expected
  attr_accessor :validate_amount_received_so_far
  attr_accessor :validate_will_receive_amount_expected
  attr_accessor :validate_reason_amount_expected_not_received

  validates_inclusion_of :received_amount_expected, in: [true, false], if: :validate_received_amount_expected?
  validates_inclusion_of :will_receive_amount_expected, in: [true, false], if: :validate_will_receive_amount_expected?

  validates :reason_amount_expected_not_received, presence: true, if: :validate_reason_amount_expected_not_received?
  validates :amount_received_so_far, presence: true, if: :validate_amount_received_so_far?

  validates :amount_received_so_far, numericality: {
    greater_than: -1,
    less_than: 2147483648,
  }, if: :validate_amount_received_so_far?

  validates :date_day, numericality: {
    greater_than: 0,
    less_than: 32,
  }, if: :validate_date_day_month_year?

  validates :date_month, numericality: {
    greater_than: 0,
    less_than: 13,
  }, if: :validate_date_day_month_year?

  validates :date_year, numericality: {
    greater_than: 1699,
    less_than: 4000,
  }, if: :validate_date_day_month_year?

  validate do

    validate_length(
      :reason_amount_expected_not_received,
      50,
      I18n.t(
        "activerecord.errors.models.progress_update_" \
          "cash_contribution.attributes.reason_amount_expected_not_received.too_long",
        word_count: 50)
    ) if validate_reason_amount_expected_not_received?

    validate_full_date(
      :date_amount_received,
      :date_day,
      :date_month,
      :date_month
    ) if validate_date_day_month_year?

  end

  # Attempts to construct a valid date from the params
  # adds an error to the record, if the attempt is invalid.
  #
  # @params [Integer] day
  # @params [Integer] month
  # @params [Integer] year
  def validate_full_date(field, day, month, year)

    if !Date.valid_date? date_year.to_i, date_month.to_i, date_day.to_i
      errors.add(
          field,
          I18n.t("activerecord.errors.models.progress_update_" \
            "cash_contribution.attributes.date_amount_received.invalid")
      )
    end

  end


  def validate_reason_amount_expected_not_received?
    validate_reason_amount_expected_not_received == true
  end

  def validate_received_amount_expected?
    validate_received_amount_expected == true
  end

  def validate_date_day_month_year?
    validate_date_day_month_year == true
  end

  def validate_amount_received_so_far?
    validate_amount_received_so_far == true
  end

  def validate_will_receive_amount_expected?
    validate_will_receive_amount_expected == true
  end

  def validate_amount_received_so_far?
    validate_amount_received_so_far == true
  end

end
