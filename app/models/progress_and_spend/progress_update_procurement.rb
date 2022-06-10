class ProgressUpdateProcurement < ApplicationRecord
  include GenericValidator

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'prgrss_updts_procurements'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true


  attr_accessor :validate_date
  attr_accessor :validate_details

  attr_accessor :date_day
  attr_accessor :date_month
  attr_accessor :date_year  

  validates :name, length: { minimum: 1, maximum: 120 }, if: :validate_details
  validates :description, length: { minimum: 1, maximum: 150 }, if: :validate_details
  validates :amount, numericality: {
    only_integer: true,
    greater_than: 9999,
    less_than: 2147483647
  }, if: :validate_details
  validates_inclusion_of :lowest_tender, in: [true, false], if: :validate_details
  validates :supplier_justification, presence: true, :unless => :lowest_tender?, if: :validate_details

  validates :date_day, numericality: {
    greater_than: 0,
    less_than: 32,
  }, if: :validate_date?
  validates :date_month, numericality: {
    greater_than: 0,
    less_than: 13,
  }, if: :validate_date?
  validates :date_year, numericality: {
    greater_than: 1699,
    less_than: 4000,
  }, if: :validate_date?

  validate do

    validate_real_date(
      :date,
      :date_day,
      :date_month,
      :date_month
    ) if validate_date?

  end

  def validate_date?
    validate_date == true
  end

  def validate_details?
    validate_details == true
  end

  def validate_real_date(field, day, month, year)
    if !Date.valid_date? date_year.to_i, date_month.to_i, date_day.to_i
      errors.add(
          field,
          I18n.t('progress_and_spend.progress_update.procurement.add_procurement.invalid_date')
      )
    end
  end
end
