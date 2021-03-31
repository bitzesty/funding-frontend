class OpenMedium < ApplicationRecord
  include ActiveModel::Validations, GenericValidator

  self.implicit_order_column = 'created_at'

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'gp_open_medium'

  belongs_to :user
  belongs_to :funding_application, optional: true

  has_one :organisation, through: :user

  has_one_attached :risk_register_file
  has_one_attached :governing_document_file
  has_many_attached :job_description_files

  # These attributes are used to set individual error messages
  # for each of the project date input fields
  attr_accessor :start_date_day
  attr_accessor :start_date_month
  attr_accessor :start_date_year
  attr_accessor :end_date_day
  attr_accessor :end_date_month
  attr_accessor :end_date_year

  attr_accessor :same_location
  attr_accessor :permission_description_yes
  attr_accessor :permission_description_x_not_sure

  attr_accessor :validate_received_advice_description
  attr_accessor :validate_first_fund_application
  attr_accessor :validate_recent_project_reference
  attr_accessor :validate_recent_project_title
  attr_accessor :validate_title
  attr_accessor :validate_permission_type
  attr_accessor :validate_permission_description_yes
  attr_accessor :validate_permission_description_x_not_sure
  attr_accessor :validate_description
  attr_accessor :validate_start_and_end_dates
  attr_accessor :validate_why_now_description
  attr_accessor :validate_same_location
  attr_accessor :validate_address
  attr_accessor :validate_difference
  attr_accessor :validate_heritage_at_risk
  attr_accessor :validate_heritage_at_risk_description
  attr_accessor :validate_heritage_attracts_visitors
  attr_accessor :validate_visitors_in_last_financial_year
  attr_accessor :validate_visitors_expected_per_year
  attr_accessor :validate_matter
  attr_accessor :validate_environmental_impacts_description
  attr_accessor :validate_heritage_description
  attr_accessor :validate_best_placed_description
  attr_accessor :validate_involvement_description
  attr_accessor :validate_other_outcomes
  attr_accessor :validate_management_description_length
  attr_accessor :validate_management_description_presence
  attr_accessor :validate_risk_register_file
  attr_accessor :validate_evaluation_description
  attr_accessor :validate_job_description_files
  attr_accessor :validate_acknowledgement_description
  attr_accessor :validate_governing_document_file

  validates_inclusion_of :first_fund_application, in: [true, false], if: :validate_first_fund_application?
  validates :recent_project_reference, presence: true, format: { with: /[A-Z]{2}[-][0-9]{2}[-][0-9]{5}/ }, if: :validate_recent_project_reference?
  validates :recent_project_title, presence: true, length: { maximum: 255 }, if: :validate_recent_project_reference?
  validates :project_title, presence: true, length: { maximum: 255 }, if: :validate_title?
  validates :description, presence: true, if: :validate_description?
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
  validates :permission_type, presence: true, if: :validate_permission_type?
  validates :permission_description_yes, presence: true, if: :validate_permission_description_yes?
  validates :permission_description_x_not_sure, presence: true, if: :validate_permission_description_x_not_sure?
  validates_inclusion_of :heritage_attracts_visitors, in: [true, false], if: :validate_heritage_attracts_visitors?
  validates_inclusion_of :heritage_at_risk, in: [true, false], if: :validate_heritage_at_risk?
  validates :heritage_at_risk_description, presence: true, if: :validate_heritage_at_risk_description?
  validates :visitors_in_last_financial_year, numericality: {
    greater_than: 0,
    less_than: 2147483648
  }, if: :validate_visitors_in_last_financial_year?
  validates :visitors_expected_per_year, numericality: {
    greater_than: 0,
    less_than: 2147483648
  }, if: :validate_visitors_expected_per_year?
  validates :environmental_impacts_description, presence: true, if: :validate_environmental_impacts_description?
  validates :involvement_description, presence: true, if: :validate_involvement_description?
  validates :management_description, presence: true, if: :validate_management_description_presence?
  validates :evaluation_description, presence: true, if: :validate_evaluation_description?
  validates :acknowledgement_description, presence: true, if: :validate_acknowledgement_description?

  validates_with ProjectValidator, if: :validate_no_errors && :validate_start_and_end_dates?

  validate do

    validate_length(
      :received_advice_description,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.received_advice_description.too_long',
        word_count: 500
      )
    ) if validate_received_advice_description?

    validate_length(
      :description,
      500,
      I18n.t('activerecord.errors.models.open_medium.attributes.description.too_long', word_count: 500)
    ) if validate_description?

    validate_length(
      :why_now_description,
      500,
      I18n.t('activerecord.errors.models.open_medium.attributes.why_now_description.too_long', word_count: 500)
    ) if validate_why_now_description?

    validate_length(
      :permission_description_x_not_sure,
      300,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.permission_description_x_not_sure.too_long',
        word_count: 300
      )
    ) if validate_permission_description_x_not_sure?

    validate_length(
      :permission_description_yes,
      300,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.permission_description_yes.too_long',
        word_count: 300
      )
    ) if validate_permission_description_yes?
    
    validate_length(
      :difference,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.difference.too_long',
        word_count: 500
      )
    ) if validate_difference?

    validate_length(
      :heritage_at_risk_description,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.heritage_at_risk_description.too_long',
        word_count: 500
      )
    ) if validate_heritage_at_risk_description?

    validate_length(
      :matter,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.matter.too_long',
        word_count: 500
      )
    ) if validate_matter?

    validate_length(
      :environmental_impacts_description,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.environmental_impacts_description.too_long',
        word_count: 500
      )
    ) if validate_environmental_impacts_description?

    validate_length(
      :heritage_description,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.heritage_description.too_long',
        word_count: 500
      )
    ) if validate_heritage_description?

    validate_length(
      :best_placed_description,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.best_placed_description.too_long',
        word_count: 500
      )
    ) if validate_best_placed_description?

    validate_length(
      :involvement_description,
      300,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.involvement_description.too_long',
        word_count: 300
      )
    ) if validate_involvement_description?

    for i in 2..9 do
      validate_length(
        "outcome_#{i}_description",
        300,
        I18n.t(
          'activerecord.errors.models.project.attributes.outcome_description.too_long',
          word_count: 300
        )
      ) if validate_other_outcomes?
    end

    validate_length(
      :management_description,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.management_description.too_long',
        word_count: 500
      )
    ) if validate_management_description_length?

    validate_length(
      :evaluation_description,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.evaluation_description.too_long',
        word_count: 500
      )
    ) if validate_evaluation_description?

    validate_file_attached(
      :job_description_files,
      I18n.t('activerecord.errors.models.open_medium.attributes.job_description_files.inclusion')
    ) if validate_job_description_files?

    validate_length(
      :acknowledgement_description,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.acknowledgement_description.too_long',
        word_count: 500
      )
    ) if validate_acknowledgement_description?

    validate_file_attached(
      :governing_document_file,
      I18n.t("activerecord.errors.models.open_medium.attributes.governing_document_file.inclusion")
    ) if validate_governing_document_file?

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

  def validate_description?
    validate_description == true
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

  def validate_permission_type?
    validate_permission_type == true
  end

  def validate_permission_description_yes?
    validate_permission_description_yes == true
  end

  def validate_permission_description_x_not_sure?
    validate_permission_description_x_not_sure == true
  end
  
  def validate_difference?
    validate_difference == true
  end

  def validate_heritage_at_risk?
    validate_heritage_at_risk == true
  end

  def validate_heritage_at_risk_description?
    validate_heritage_at_risk_description == true
  end

  def validate_heritage_attracts_visitors?
    validate_heritage_attracts_visitors == true
  end

  def validate_visitors_in_last_financial_year?
    validate_visitors_in_last_financial_year == true
  end

  def validate_visitors_expected_per_year?
    validate_visitors_expected_per_year == true
  end

  def validate_matter?
    validate_matter == true
  end

  def validate_environmental_impacts_description?
    validate_environmental_impacts_description == true
  end

  def validate_heritage_description?
    validate_heritage_description == true
  end

  def validate_best_placed_description?
    validate_best_placed_description == true
  end

  def validate_involvement_description?
    validate_involvement_description == true
  end

  def validate_other_outcomes?
    validate_other_outcomes == true
  end

  def validate_management_description_presence?
    validate_management_description_presence == true
  end

  def validate_management_description_length?
    validate_management_description_length == true
  end

  def validate_risk_register_file?
    validate_risk_register_file == true
  end

  def validate_evaluation_description?
    validate_evaluation_description == true
  end

  def validate_job_description_files?
    validate_job_description_files == true
  end

  def validate_acknowledgement_description?
    validate_acknowledgement_description == true
  end

  def validate_governing_document_file?
    validate_governing_document_file == true
  end

  enum permission_type: {
    yes: 0,
    no: 1,
    x_not_sure: 2
  }

end
