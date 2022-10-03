class HighSpend < ApplicationRecord
  include ActiveModel::Validations, GenericValidator

  belongs_to :payment_request, optional: true

  attr_accessor :validate_save_continue
  attr_accessor :validate_file

  attr_accessor :cost_headings

  attr_accessor :date_day
  attr_accessor :date_month
  attr_accessor :date_year
  attr_accessor :full_date

  has_one_attached :evidence_of_spend_file

  validates :cost_heading, presence: true, if: :validate_save_continue?
  validates :description, presence: true, if: :validate_save_continue?

  validates :amount, numericality: {
    greater_than: :spend_threshold,
    less_than: 2147483648
  }, if: :validate_save_continue?

  validates :vat_amount, numericality: {
    greater_than: -1,
    less_than: 2147483648
  }, if: :validate_save_continue?

  validates :date_day, numericality: {
    greater_than: 0,
    less_than: 32,
  }, if: :validate_save_continue?

  validates :date_month, numericality: {
    greater_than: 0,
    less_than: 13,
  }, if: :validate_save_continue?

  validates :date_year, numericality: {
    greater_than: 1699,
    less_than: 4000,
  }, if: :validate_save_continue?

  validate do

    # Ensure the given cost heading exists in the headings list
    if validate_save_continue? &&
      self.cost_headings.exclude?(self.cost_heading)

        self.errors.add(
          'cost_heading',
          I18n.t("activerecord.errors.models.high_spend.attributes." \
            "cost_heading.invalid")
        )

    end

    validate_length(
      :description,
      50,
      I18n.t("generic.word_count", max_words: 50)
    ) if validate_save_continue?

    validate_full_date(
      :full_date,
      :date_day,
      :date_month,
      :date_month
    ) if validate_save_continue?

    validate_file_attached(
        :evidence_of_spend_file,
        I18n.t("activerecord.errors.models.high_spend.attributes." \
            "evidence_of_spend_file.inclusion")
    ) if validate_file?

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
          I18n.t("activerecord.errors.models.high_spend" \
            ".attributes.full_date.invalid")
      )
    end

  end

  def validate_save_continue?
    validate_save_continue == true
  end

  def validate_file?
    validate_file == true
  end


end
