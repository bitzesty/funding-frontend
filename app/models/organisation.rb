class Organisation < ApplicationRecord
  include ActiveModel::Validations, GenericValidator, OrganisationHelper

  after_find do |organisation|

    unless organisation.updated_at.today? || organisation.salesforce_account_id.nil? \
      || salesforce_checked_today?(organisation)

      Rails.logger.info "Checking and updating Org with id: #{organisation.id}"
      update_existing_organisation_from_salesforce_details(organisation)

    end 
  end

  self.implicit_order_column = "created_at"

  has_many :pre_applications
  has_many :funding_applications

  has_many :organisations_org_types, inverse_of: :organisation
  has_many :org_types, through: :organisations_org_types

  has_many :users_organisations, inverse_of: :organisation
  has_many :users, through: :users_organisations

  accepts_nested_attributes_for :organisations_org_types, allow_destroy: true

  attr_accessor :has_custom_org_type

  attr_accessor :validate_name
  attr_accessor :validate_org_type
  attr_accessor :validate_custom_org_type
  attr_accessor :validate_address
  attr_accessor :validate_mission
  attr_accessor :validate_main_purpose_and_activities
  attr_accessor :validate_board_members_or_trustees
  attr_accessor :validate_vat_registered
  attr_accessor :validate_vat_number
  attr_accessor :validate_company_number
  attr_accessor :validate_charity_number
  attr_accessor :validate_social_media_info
  attr_accessor :validate_spend_in_last_financial_year
  attr_accessor :validate_unrestricted_funds

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
    greater_than: -1,
    less_than: 2147483648,
    allow_nil: true
  }, if: :validate_board_members_or_trustees?
  validates_inclusion_of :vat_registered, in: [true, false], if: :validate_vat_registered?
  validates :vat_number, length: { minimum: 9, maximum: 12 }, if: :validate_vat_number?
  validates :spend_in_last_financial_year, numericality: { greater_than: 0, allow_nil: true }, if: :validate_spend_in_last_financial_year?
  validates :unrestricted_funds, numericality: { greater_than: 0, allow_nil: true }, if: :validate_unrestricted_funds?
  validates :company_number, length: { maximum: 20 }, if: :validate_company_number?
  validates :charity_number, length: { maximum: 20 }, if: :validate_charity_number?
  

  validate do

    validate_length(
      :main_purpose_and_activities,
      500,
      I18n.t('activerecord.errors.models.organisation.attributes.main_purpose_and_activities.too_long', word_count: 500)
    ) if validate_main_purpose_and_activities?

    validate_length(
      :social_media_info,
      500,
      I18n.t('activerecord.errors.models.organisation.attributes.social_media_info.too_long', word_count: 500)
    ) if validate_social_media_info?

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

  def validate_main_purpose_and_activities?
    validate_main_purpose_and_activities == true
  end

  def validate_board_members_or_trustees?
    validate_board_members_or_trustees == true
  end
  
  def validate_vat_number?
    validate_vat_number == true
  end

  def validate_company_number?
    validate_company_number == true
  end

  def validate_charity_number?
    validate_charity_number == true
  end

  def validate_vat_registered?
    validate_vat_registered == true
  end

  def validate_social_media_info?
    validate_social_media_info == true
  end

  def validate_spend_in_last_financial_year?
    validate_spend_in_last_financial_year == true
  end
  
  def validate_unrestricted_funds?
    validate_unrestricted_funds == true
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

  # Org types are set when an applicant initially completes organisation
  # details (The organisation_org_types table has not been used.)
  #
  # The partial, that captures the org types, only shows orgs from 1 to 10
  # 10 is 'other_public_sector_organisation' and the last type a user
  # can select. So any additional org types will require changes in these
  # partials.  And new translations for the application, pre-application,
  # and organisation summary screens.
  #
  # Salesforce merges some org types upon submission like:
  # - Faith based or church organisation (instead of faith or church)
  # - Community of Voluntary group (instead of community or voluntary group)
  # - Registered company or Community Interest Company (instead of reg or com)
  #
  # Future work intends to address this, so changes to an organisation type in
  # Salesforce can be reflected in what FFE stores,
  # when after_find runs above.
  #
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
