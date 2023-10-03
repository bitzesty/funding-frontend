class LegalSignatory < ApplicationRecord

  has_many :funding_applications_legal_sigs, inverse_of: :legal_signatory
  has_one :funding_applications, through: :funding_applications_legal_sigs

  self.implicit_order_column = "created_at"

  attr_accessor :validate_role
  attr_accessor :validate_name
  attr_accessor :validate_email_address
  attr_accessor :validate_phone_number

  validates :role, length: { minimum: 1, maximum: 80 }

  validates :name, length: { minimum: 1, maximum: 80 }

  # the custom regex below ensures that a domain 
  # is present and also allows tags.
  validates :email_address,
            format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }

  def validate_role?
    validate_role == true
  end

  def validate_name?
    validate_name == true
  end

  def validate_email_address?
    validate_email_address == true
  end

  def validate_phone_number?
    validate_phone_number == true
  end

end
