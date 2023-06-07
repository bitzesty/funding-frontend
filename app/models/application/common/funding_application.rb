class FundingApplication < ApplicationRecord
  include ActiveModel::Validations
  include GenericValidator

  has_many :addresses, through: :funding_application_addresses

  has_one :project
  has_one :open_medium
  has_one :payment_details
  has_one :agreement
  has_one :arrears_journey_tracker
  has_many :completed_arrears_journeys
  belongs_to :organisation, optional: true

  has_many :funding_applications_people, inverse_of: :funding_application
  has_many :people, through: :funding_applications_people

  has_many :funding_applications_dclrtns, inverse_of: :funding_application
  has_many :declarations, through: :funding_applications_dclrtns

  has_many :funding_applications_costs, inverse_of: :funding_application
  has_many :project_costs, through: :funding_applications_costs

  has_many :funding_applications_nccs, inverse_of: :funding_application
  has_many :non_cash_contributions, through: :funding_applications_nccs

  has_many :funding_applications_vlntrs, inverse_of: :funding_application
  has_many :volunteers, through: :funding_applications_vlntrs

  has_many :funding_applications_ccs, inverse_of: :funding_application
  has_many :cash_contributions, through: :funding_applications_ccs

  has_many :funding_applications_evidences, inverse_of: :funding_application
  has_many :evidence_of_support, through: :funding_applications_evidences, foreign_key: 'evidence_of_support'

  has_many :funding_applications_pay_reqs, inverse_of: :funding_application
  has_many :payment_requests, through: :funding_applications_pay_reqs

  has_many :funding_applications_progress_updates, inverse_of: :funding_application
  has_many :progress_updates, through: :funding_applications_progress_updates

  has_many :funding_applications_legal_sigs, inverse_of: :funding_application
  has_many :legal_signatories, through: :funding_applications_legal_sigs

  has_many_attached :additional_evidence_files

  accepts_nested_attributes_for(
    :organisation,
    :people,
    :declarations,
    :volunteers,
    :project_costs,
    :cash_contributions,
    :evidence_of_support,
    :non_cash_contributions,
    :legal_signatories
  )

  attr_accessor :validate_people
  attr_accessor :validate_declarations
  attr_accessor :validate_project_costs
  attr_accessor :validate_has_associated_project_costs
  attr_accessor :validate_cash_contributions_question
  attr_accessor :validate_cash_contributions
  attr_accessor :validate_evidence_of_support
  attr_accessor :validate_non_cash_contributions
  attr_accessor :validate_non_cash_contributions_question
  attr_accessor :validate_new_evidence
  attr_accessor :validate_additional_evidence_files
  attr_accessor :validate_legal_signatories
  attr_accessor :validate_applicant_is_legal_sig
  attr_accessor :validate_applicant_role
  attr_accessor :validate_details_correct
  attr_accessor :validate_legal_signatories_email_uniqueness
  attr_accessor :validate_migrated_details_correct

  attr_accessor :cash_contributions_question
  attr_accessor :non_cash_contributions_question
  attr_accessor :payment_still_details_question
  attr_accessor :new_evidence
  attr_accessor :applicant_is_legal_sig
  attr_accessor :applicant_role
  attr_accessor :details_correct
  attr_accessor :migrated_details_correct


  validates_associated :organisation
  validates_associated :people if :validate_people
  validates_associated :declarations, if: :validate_declarations?
  validates_associated :project_costs, if: :validate_project_costs?
  validates_associated :cash_contributions, if: :validate_cash_contributions?
  validates_associated :evidence_of_support, if: :validate_evidence_of_support?
  validates_associated :non_cash_contributions, if: :validate_non_cash_contributions?
  validates_associated :legal_signatories, if: :validate_legal_signatories?

  validates :details_correct, presence: true, if: :validate_details_correct?
  validates :migrated_details_correct, presence: true, if: :validate_migrated_details_correct?
  validates :project_costs, presence: true, if: :validate_has_associated_project_costs?
  validates :applicant_is_legal_sig, presence: true, if: :validate_applicant_is_legal_sig?
  validates :applicant_role, presence: true, if: :validate_applicant_role?
  validates_inclusion_of :cash_contributions_question,
    in: ["true", "false"],
    if: :validate_cash_contributions_question?
  validates_inclusion_of :non_cash_contributions_question,
    in: ["true", "false"],
    if: :validate_non_cash_contributions_question?
  validates_inclusion_of :new_evidence, in: ["true", "false"], if: :validate_new_evidence?

  validates_with SignatoryEmailValidator, if: :validate_legal_signatories_email_uniqueness?

  def validate_details_correct?
    validate_details_correct
  end

  def validate_migrated_details_correct?
    validate_migrated_details_correct == true
  end


  def validate_applicant_is_legal_sig?
    validate_applicant_is_legal_sig == true
  end

  def validate_applicant_role?
    validate_applicant_role == true
  end

  def validate_people?
    validate_people == true
  end

  def validate_declarations?
    validate_declarations == true
  end

  def validate_evidence_of_support?
    validate_evidence_of_support == true
  end

  def validate_non_cash_contributions_question?
    validate_non_cash_contributions_question == true
  end

  def validate_non_cash_contributions?
    validate_non_cash_contributions == true
  end

  def validate_cash_contributions_question?
    validate_cash_contributions_question == true
  end

  def validate_cash_contributions?
    validate_cash_contributions == true
  end

  def validate_project_costs?
    validate_project_costs == true
  end

  def validate_has_associated_project_costs?
    validate_has_associated_project_costs == true
  end

  def validate_new_evidence?
    validate_new_evidence == true
  end

  def validate_additional_evidence_files?
    validate_additional_evidence_files == true
  end

  def validate_legal_signatories?
    validate_legal_signatories == true
  end

  def validate_legal_signatories_email_uniqueness?
    validate_legal_signatories_email_uniqueness == true
  end

  validate do
    validate_file_attached(
        :additional_evidence_files,
        I18n.t("activerecord.errors.models.funding_application.attributes.additional_evidence_files.inclusion")
    ) if validate_additional_evidence_files?
  end

  private

  # Method to build an array of specified values from an 
  # ActiveRecord::Collection.
  #
  # @param [ActiveRecord::Collection] active_record_collection An instance of
  #                                                            ActiveRecord::Collection
  # @param [String]                   item_key                 A reference to an item key
  def active_record_collection_to_array(active_record_collection, item_key)
      temp_array = []

      active_record_collection.each do |active_record_item|
          temp_array.append(active_record_item[item_key])
      end

      return {results: temp_array}
  end

  # Method to initialise instance variables containing the response to each 
  # declaration question. question_response will be the applicants response.
  #
  # @param [ActiveRecord::Collection] active_record_collection An instance of
  #                                                            ActiveRecord::Collection
  def get_declarations(active_record_collection)

    active_record_collection.each do |active_record_item|

      question_response = active_record_item.json['question_response']

      case active_record_item.declaration_type
        when 'agreed_to_terms'
          @declaration_agreed_to_terms = question_response ? 
            {results: [question_response]} : {results: [""]}
        when 'data_protection_and_research'
          @declaration_data_protection_and_research = question_response ? 
            {results: [question_response]} : {results: [""]}
        when 'contact'
          @declaration_contact = question_response ? 
            {results: [question_response]} : {results: [""]}
        when 'confirmation'
          @declaration_confirmation = question_response ? 
            {results: [question_response]} : {results: [""]}
        when 'form_feedback'
          @declaration_form_feedback = question_response
        when 'data_and_foi'
          @declaration_data_and_foi = question_response
      end

    end

  end

  # Apart from development and delivery, these align to grant-level
  #
  # is_3_to_10k: Use this if Salesforce has small grant record type. No
  # need to check grant value.
  #
  # is_10_to_100k: Medium 1 grant - Check medium grant record type,
  # then grant value
  #
  # is_100_to_250k: Medium 2 grant - Check for medium grant record type,
  # then grant value
  #
  # dev_to_100k: Development grant up to and including 100k, Check record
  # type then look at development grant value
  #
  # dev_over_100k: Development grant over 100k. Check record type then
  # look at development grant value
  #
  # del_250k_to_5mm: Delivery grant, between 250k and 5 Million.
  # Check record type.  No need to check value at the moment.
  #
  enum award_type: {
    is_3_to_10k: 0,
    is_10_to_100k: 1,
    is_100_to_250k: 2,
    dev_to_100k: 4,
    dev_over_100k: 5,
    del_250k_to_5mm: 6,
    migrated_large_delivery: 7,
    migrated_medium_over_100k: 8,
    award_type_unknown: 3
  }, _default: :award_type_unknown

  # Unknown, existing applications that pre-date status, or are new
  # payment_can_start, used to see if arrears, M1 50%, Dev 50% payment can start
  # m1_40_payment_can_start, M1 40% payment journey can start
  # m1_40_payment_complete, M1_40% payment journey concluded.
  enum status: {
    unknown: 0,
    payment_can_start: 1,
    m1_40_payment_can_start: 2,
    m1_40_payment_complete: 3,
    dev_40_payment_can_start: 4,
    dev_40_payment_complete: 5
  }, _default: :unknown

end

