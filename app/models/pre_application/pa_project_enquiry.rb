class PaProjectEnquiry < ApplicationRecord
  include ActiveModel::Validations, GenericValidator
  # This overrides Rails attempting to pluralise the model name
  self.table_name = "pa_project_enquiries"
  belongs_to :pre_application

  attr_accessor :validate_heritage_focus
  attr_accessor :validate_what_project_does
  attr_accessor :validate_programme_outcomes
  attr_accessor :validate_project_reasons
  attr_accessor :validate_project_participants
  attr_accessor :validate_project_timescales
  attr_accessor :validate_project_likely_cost
  attr_accessor :validate_potential_funding_amount
  attr_accessor :validate_working_title
  attr_accessor :validate_project_likely_cost

  validates :working_title, length: { maximum: 255 }, if: :validate_working_title?
  validates :potential_funding_amount, numericality: {
    greater_than: 0,
    less_than: 250001,
    allow_nil: true
  }, if: :validate_potential_funding_amount?

  validate do

    validate_length(
      :what_project_does,
      200,
      I18n.t('activerecord.errors.models.pa_project_enquiry.attributes.what_project_does.too_long', word_count: 200)
    ) if validate_what_project_does?

    validate_length(
      :programme_outcomes,
      200,
      I18n.t('activerecord.errors.models.pa_project_enquiry.attributes.programme_outcomes.too_long', word_count: 200)
    ) if validate_programme_outcomes?

    validate_length(
      :heritage_focus,
      100,
      I18n.t('activerecord.errors.models.pa_project_enquiry.attributes.heritage_focus.too_long', word_count: 100)
    ) if validate_heritage_focus?

    validate_length(
      :project_reasons,
      200,
      I18n.t('activerecord.errors.models.pa_project_enquiry.attributes.project_reasons.too_long', word_count: 200)
    ) if validate_project_reasons?

    validate_length(
      :project_timescales,
      50,
      I18n.t('activerecord.errors.models.pa_project_enquiry.attributes.project_timescales.too_long', word_count: 50)
    ) if validate_project_timescales?

    validate_length(
      :project_participants,
      100,
      I18n.t('activerecord.errors.models.pa_project_enquiry.attributes.project_participants.too_long', word_count: 100)
    ) if validate_project_participants?

    validate_length(
      :project_likely_cost,
      200,
      I18n.t("activerecord.errors.models.pa_project_enquiry.attributes.project_likely_cost.too_long", word_count: 200)
    ) if validate_project_likely_cost?

  end

  def validate_heritage_focus?
    validate_heritage_focus == true
  end

  def validate_what_project_does?
    validate_what_project_does == true
  end

  def validate_programme_outcomes?
    validate_programme_outcomes == true
  end

  def validate_project_reasons?
    validate_project_reasons == true
  end

  def validate_project_participants?
    validate_project_participants == true
  end

  def validate_project_timescales?
    validate_project_timescales == true
  end

  def validate_project_likely_cost?
    validate_project_likely_cost == true
  end

  def validate_potential_funding_amount?
    validate_potential_funding_amount == true
  end

  def validate_working_title?
    validate_working_title == true
  end

end