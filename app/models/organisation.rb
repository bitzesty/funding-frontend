class Organisation < ApplicationRecord
  include ActiveModel::Validations, GenericValidator

  self.implicit_order_column = "created_at"

  has_many :legal_signatories
  has_many :pre_applications
  has_many :funding_applications

  has_many :organisations_org_types, inverse_of: :organisation
  has_many :org_types, through: :organisations_org_types

  has_many :users_organisations, inverse_of: :organisation
  has_many :users, through: :users_organisations

  accepts_nested_attributes_for :legal_signatories
  accepts_nested_attributes_for :organisations_org_types, allow_destroy: true

  attr_accessor :has_custom_org_type

  attr_accessor :validate_name
  attr_accessor :validate_org_type
  attr_accessor :validate_custom_org_type
  attr_accessor :validate_address
  attr_accessor :validate_mission
  attr_accessor :validate_legal_signatories
  attr_accessor :validate_main_purpose_and_activities
  attr_accessor :validate_board_members_or_trustees
  attr_accessor :validate_vat_registered
  attr_accessor :validate_vat_number


  validates_associated :legal_signatories,
                       if: :validate_legal_signatories?

  validates :org_type, presence: true, if: :validate_org_type?
  validates :custom_org_type, presence: true, if: :validate_custom_org_type?
  validate :validate_mission_array, if: :validate_mission?
  validates :name, presence: true, if: :validate_name?
  validates :name, presence: true, if: :validate_address?
  validates :line1, presence: true, if: :validate_address?
  validates :townCity, presence: true, if: :validate_address?
  validates :county, presence: true, if: :validate_address?
  validates :postcode, presence: true, if: :validate_address?
  validates :main_purpose_and_activities, presence: true, if: :validate_main_purpose_and_activities?
  validates :board_members_or_trustees, numericality: {
    greater_than: 0,
    less_than: 2147483648,
    allow_nil: true
  }, if: :validate_board_members_or_trustees?
  validates_inclusion_of :vat_registered, in: [true, false], if: :validate_vat_registered?
  validates :vat_number, length: { minimum: 9, maximum: 12 }, if: :validate_vat_number?

  validate do

    validate_length(
      :main_purpose_and_activities,
      500,
      I18n.t('activerecord.errors.models.organisation.attributes.main_purpose_and_activities.too_long', word_count: 500)
    ) if validate_main_purpose_and_activities?

  end

  def validate_name?
    validate_name == true
  end

  def validate_org_type?
    validate_org_type == true
  end

  def validate_custom_org_type?
    validate_custom_org_type == true
  end

  def validate_address?
    validate_address == true
  end

  def validate_mission?
    validate_mission == true
  end

  def validate_legal_signatories?
    validate_legal_signatories == true
  end

  def validate_main_purpose_and_activities?
    validate_main_purpose_and_activities == true
  end

  def validate_board_members_or_trustees?
    validate_board_members_or_trustees == true
  end
  
  def validate_vat_number?
    validate_vat_number == true
  end

  def validate_vat_registered?
    validate_vat_registered == true
  end

  # Custom validator to determine whether any of the items in the incoming mission array
  # are not included in the expected list of options
  def validate_mission_array
    if mission.present?
      mission.each do |m|
        if !["black_or_minority_ethnic_led",
             "disability_led",
             "lgbt_plus_led",
             "female_led",
             "young_people_led",
             "mainly_catholic_community_led",
             "mainly_protestant_community_led"].include? m
          errors.add(:mission, m + " is not a valid selection")
        end
      end
    end
  end

  enum org_type: {
      registered_charity: 0,
      local_authority: 1,
      registered_company: 2,
      community_interest_company: 3,
      faith_based_organisation: 4,
      church_organisation: 5,
      community_group: 6,
      voluntary_group: 7,
      individual_private_owner_of_heritage: 8,
      other: 9,
      other_public_sector_organisation: 10
  }

end