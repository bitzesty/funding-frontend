class OpenMedium < ApplicationRecord
  include ActiveModel::Validations, GenericValidator

  self.implicit_order_column = 'created_at'

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'gp_open_medium'

  belongs_to :user
  belongs_to :funding_application, optional: true

  has_one :organisation, through: :user

  # These attributes are used to set individual error messages
  # for each of the project date input fields
  attr_accessor :start_date_day
  attr_accessor :start_date_month
  attr_accessor :start_date_year
  attr_accessor :end_date_day
  attr_accessor :end_date_month
  attr_accessor :end_date_year

  attr_accessor :same_location

  attr_accessor :validate_received_advice_description
  attr_accessor :validate_first_fund_application
  attr_accessor :validate_recent_project_reference
  attr_accessor :validate_recent_project_title
  attr_accessor :validate_title
  attr_accessor :validate_start_and_end_dates
  attr_accessor :validate_why_now_description
  attr_accessor :validate_same_location
  attr_accessor :validate_address

  validates_inclusion_of :first_fund_application, in: [true, false], if: :validate_first_fund_application?
  validates :recent_project_reference, presence: true, format: { with: /[A-Z]{2}[-][0-9]{2}[-][0-9]{5}/ }, if: :validate_recent_project_reference?
  validates :recent_project_title, presence: true, length: { maximum: 255 }, if: :validate_recent_project_reference?
  validates :project_title, presence: true, length: { maximum: 255 }, if: :validate_title?
  validates :start_date_day, presence: true, if: :validate_start_and_end_dates?
  validates :start_date_month, presence: true, if: :validate_start_and_end_dates?
  validates :start_date_year, presence: true, if: :validate_start_and_end_dates?
  validates :end_date_day, presence: true, if: :validate_start_and_end_dates?
  validates :end_date_month, presence: true, if: :validate_start_and_end_dates?
  validates :end_date_year, presence: true, if: :validate_start_and_end_dates?
  validates :why_now_description, presence: true, if: :validate_why_now_description?
  validates :same_location, presence: true, if: :validate_same_location?
  validates :line1, presence: true, if: :validate_address?
  validates :townCity, presence: true, if: :validate_address?
  validates :county, presence: true, if: :validate_address?
  validates :postcode, presence: true, if: :validate_address?

  validates_with ProjectValidator, if: :validate_no_errors && :validate_start_and_end_dates?


  validate do

    validate_length(
      :received_advice_description,
      500,
      I18n.t('activerecord.errors.models.open_medium.attributes.received_advice_description.too_long', word_count: 500)
    ) if validate_received_advice_description?

    validate_length(
      :why_now_description,
      500,
      I18n.t('activerecord.errors.models.open_medium.attributes.why_now_description.too_long', word_count: 500)
    ) if validate_why_now_description?

  end

  def validate_received_advice_description?
    validate_received_advice_description == true
  end

  def validate_first_fund_application?
    validate_first_fund_application == true
  end

  def validate_recent_project_reference?
    validate_recent_project_reference == true
  end

  def validate_recent_project_title?
    validate_recent_project_title == true
  end

  def validate_title?
    validate_title == true
  end

  def validate_address?
    validate_address == true
  end

  def validate_start_and_end_dates?
    validate_start_and_end_dates == true  
  end

  def validate_why_now_description?
    validate_why_now_description == true
  end

  def validate_same_location?
    validate_same_location == true
  end

end
