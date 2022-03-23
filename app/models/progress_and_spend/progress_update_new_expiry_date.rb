class ProgressUpdateNewExpiryDate < ApplicationRecord
  include GenericValidator

  self.table_name = 'prgrss_updts_new_expiry_date'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  attr_accessor :date_day
  attr_accessor :date_month
  attr_accessor :date_year

  validates :description, presence: true

  validates :date_day, numericality: {
    greater_than: 0,
    less_than: 32,
  }

  validates :date_month, numericality: {
    greater_than: 0,
    less_than: 13,
  }

  validates :date_year, numericality: {
    greater_than: 1699,
    less_than: 4000,
  }

  validate do

    validate_length(
      :description,
      50,
      I18n.t(
        "activerecord.errors.models.progress_update_new_" \
          "expiry_date.attributes.description.too_long",
        word_count: 50)
    )

    validate_full_date(
      :full_date,
      :date_day,
      :date_month,
      :date_month
    )

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
            "new_expiry_date.attributes.full_date.invalid")
      )
    end

  end

end
