class OpenMedium < ApplicationRecord
  include ActiveModel::Validations, GenericValidator

  self.implicit_order_column = 'created_at'

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'gp_open_medium'

  has_many :open_medium_heritage_designations, inverse_of: :open_medium, foreign_key: 'gp_open_medium_id'
  has_many :heritage_designations, through: :open_medium_heritage_designations

  belongs_to :user
  belongs_to :funding_application, optional: true

  has_one :organisation, through: :user

  has_one_attached :partnership_agreement_file
  has_one_attached :ownership_file
  has_one_attached :capital_work_file
  has_one_attached :risk_register_file
  has_one_attached :governing_document_file
  has_one_attached :project_plan_file
  has_one_attached :full_cost_recovery_file
  has_many_attached :job_description_files
  has_many_attached :accounts_files
  has_many_attached :work_brief_files
  has_many_attached :project_image_files

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
  attr_accessor :confirm_declaration

  attr_accessor :validate_received_advice_description
  attr_accessor :validate_first_fund_application
  attr_accessor :validate_recent_project_reference
  attr_accessor :validate_recent_project_title
  attr_accessor :validate_title
  attr_accessor :validate_acquisition
  attr_accessor :validate_capital_work
  attr_accessor :validate_permission_type
  attr_accessor :validate_permission_description_yes
  attr_accessor :validate_permission_description_x_not_sure
  attr_accessor :validate_description
  attr_accessor :validate_start_and_end_dates
  attr_accessor :validate_why_now_description
  attr_accessor :validate_same_location
  attr_accessor :validate_address
  attr_accessor :validate_difference
  attr_accessor :validate_ownership_type
  attr_accessor :validate_ownership_type_org_description
  attr_accessor :validate_ownership_type_pp_description
  attr_accessor :validate_ownership_type_neither_description
  attr_accessor :validate_heritage_at_risk
  attr_accessor :validate_heritage_at_risk_description
  attr_accessor :validate_heritage_designations
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
  attr_accessor :validate_accounts_files
  attr_accessor :validate_project_plan_file
  attr_accessor :validate_work_brief_files
  attr_accessor :validate_project_image_files
  attr_accessor :validate_full_cost_recovery_file
  attr_accessor :validate_is_partnership
  attr_accessor :validate_partnership_details
  attr_accessor :validate_confirm_declaration

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
  validates_inclusion_of :capital_work, in: [true, false], if: :validate_capital_work?
  validates_inclusion_of :acquisition, in: [true, false], if: :validate_acquisition?
  validates :permission_type, presence: true, if: :validate_permission_type?
  validates :permission_description_yes, presence: true, if: :validate_permission_description_yes?
  validates :permission_description_x_not_sure, presence: true, if: :validate_permission_description_x_not_sure?
  # validates :ownership_type, presence: true, if: :validate_ownership_type?
  validates_inclusion_of :ownership_type, in: ['organisation', 'project_partner', 'neither', 'na'], if: :validate_ownership_type?
  validates :ownership_type_org_description, presence: true, if: :validate_ownership_type_org_description?
  validates :ownership_type_pp_description, presence: true, if: :validate_ownership_type_pp_description?
  validates :ownership_type_neither_description, presence: true, if: :validate_ownership_type_neither_description?
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
  validates_inclusion_of :is_partnership, in: [true, false], if: :validate_is_partnership?
  validates :partnership_details, presence: true, if: :validate_partnership_details?
  validates_inclusion_of :confirm_declaration,
                          in: ["true"],
                          if: :validate_confirm_declaration?

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
      :ownership_type_org_description,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.ownership_type_org_description.too_long',
        word_count: 500
      )
    ) if validate_ownership_type_org_description?

    validate_length(
      :ownership_type_pp_description,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.ownership_type_pp_description.too_long',
        word_count: 500
      )
    ) if validate_ownership_type_pp_description?

    validate_length(
      :ownership_type_neither_description,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.ownership_type_neither_description.too_long',
        word_count: 500
      )
    ) if validate_ownership_type_neither_description?

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

    if validate_heritage_designations?

      validate_length(
        :hd_grade_1_description,
        300,
        I18n.t(
          'activerecord.errors.models.open_medium.attributes.hd_grade_1_description.too_long',
          word_count: 300
        )
      )

      validate_length(
        :hd_grade_2_b_description,
        300,
        I18n.t(
          'activerecord.errors.models.open_medium.attributes.hd_grade_2_b_description.too_long',
          word_count: 300
        )
      )

      validate_length(
        :hd_grade_2_c_description,
        300,
        I18n.t(
          'activerecord.errors.models.open_medium.attributes.hd_grade_2_c_description.too_long',
          word_count: 300
        )
      )

      validate_length(
        :hd_local_list_description,
        300,
        I18n.t(
          'activerecord.errors.models.open_medium.attributes.hd_local_list_description.too_long',
          word_count: 300
        )
      )

      validate_length(
        :hd_monument_description,
        300,
        I18n.t(
          'activerecord.errors.models.open_medium.attributes.hd_monument_description.too_long',
          word_count: 300
        )
      )

      validate_length(
        :hd_historic_ship_description,
        300,
        I18n.t(
          'activerecord.errors.models.open_medium.attributes.hd_historic_ship_description.too_long',
          word_count: 300
        )
      )

      validate_length(
        :hd_grade_1_park_description,
        300,
        I18n.t(
          'activerecord.errors.models.open_medium.attributes.hd_grade_1_park_description.too_long',
          word_count: 300
        )
      )

      validate_length(
        :hd_grade_2_park_description,
        300,
        I18n.t(
          'activerecord.errors.models.open_medium.attributes.hd_grade_2_park_description.too_long',
          word_count: 300
        )
      )

      validate_length(
        :hd_grade_2_star_park_description,
        300,
        I18n.t(
          'activerecord.errors.models.open_medium.attributes.hd_grade_2_star_park_description.too_long',
          word_count: 300
        )
      )

      validate_length(
        :hd_other_description,
        300,
        I18n.t(
          'activerecord.errors.models.open_medium.attributes.hd_other_description.too_long',
          word_count: 300
        )
      )

    end

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
      :partnership_details,
      500,
      I18n.t(
        'activerecord.errors.models.open_medium.attributes.partnership_details.too_long',
        word_count: 500
      )
    ) if validate_partnership_details?

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

    validate_file_attached(
      :accounts_files,
      I18n.t('activerecord.errors.models.open_medium.attributes.accounts_files.inclusion')
    ) if validate_accounts_files?

    validate_file_attached(
      :project_plan_file,
      I18n.t('activerecord.errors.models.open_medium.attributes.project_plan_file.inclusion')
    ) if validate_project_plan_file?

    validate_file_attached(
      :work_brief_files,
      I18n.t('activerecord.errors.models.open_medium.attributes.work_brief_files.inclusion')
    ) if validate_work_brief_files?

    validate_file_attached(
      :project_image_files,
      I18n.t('activerecord.errors.models.open_medium.attributes.project_image_files.inclusion')
    ) if validate_project_image_files?

    validate_file_attached(
      :full_cost_recovery_file,
      I18n.t('activerecord.errors.models.open_medium.attributes.full_cost_recovery_file.inclusion')
    ) if validate_full_cost_recovery_file?

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

  def validate_capital_work?
    validate_capital_work == true
  end

  def validate_acquisition?
    validate_acquisition == true
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

  def validate_ownership_type?
    validate_ownership_type == true
  end

  def validate_ownership_type_org_description?
    validate_ownership_type_org_description == true
  end

  def validate_ownership_type_pp_description?
    validate_ownership_type_pp_description == true
  end

  def validate_ownership_type_neither_description?
    validate_ownership_type_neither_description == true
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

  def validate_heritage_designations?
    validate_heritage_designations == true
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

  def validate_accounts_files?
    validate_accounts_files == true
  end

  def validate_project_plan_file?
    validate_project_plan_file == true
  end

  def validate_work_brief_files?
    validate_work_brief_files == true
  end

  def validate_project_image_files?
    validate_project_image_files == true
  end

  def validate_full_cost_recovery_file?
    validate_full_cost_recovery_file == true
  end

  def validate_is_partnership?
    validate_is_partnership == true
  end

  def validate_partnership_details?
    validate_partnership_details == true
  end

  def validate_confirm_declaration?
    validate_confirm_declaration == true
  end

  enum permission_type: {
    yes: 0,
    no: 1,
    x_not_sure: 2
  }

end
