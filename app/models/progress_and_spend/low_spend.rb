class LowSpend < ApplicationRecord
  include ActiveModel::Validations, GenericValidator

  belongs_to :payment_request, optional: true

  attr_accessor :validate_vat_amount
  attr_accessor :validate_total_amount

  validates :total_amount, numericality: {
    greater_than: 0,
    less_than: 2147483648
  }, if: :validate_vat_amount?

  validates :vat_amount, numericality: {
    greater_than: 0,
    less_than: 2147483648
  }, if: :validate_total_amount?
  
  def validate_vat_amount?
    validate_vat_amount ==true
  end

  def validate_total_amount?
    validate_total_amount ==true
  end     

end
