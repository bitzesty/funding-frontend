class ProgressUpdateRisk < ApplicationRecord
  include GenericValidator


  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'prgrss_updts_risks'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  attr_accessor :yes_still_a_risk_description
  attr_accessor :no_still_a_risk_description

  attr_accessor :validate_yes_still_a_risk_description
  attr_accessor :validate_no_still_a_risk_description

  validates :description, presence: true
  validates :likelihood, presence: true
  validates :impact, presence: true
  validates :is_still_risk, inclusion: { in: [ true, false ] }
  validates :yes_still_a_risk_description, presence: true,
    if: :validate_yes_still_a_risk_description?
  validates :no_still_a_risk_description, presence: true,
    if: :validate_no_still_a_risk_description?


  validate do

    validate_length(
      :description,
      50,
      I18n.t(
        "activerecord.errors.models.progress_update_" \
          "risk.attributes.description.too_long",
        word_count: 50)
    )

  end

  def validate_yes_still_a_risk_description?
    validate_yes_still_a_risk_description == true
  end

  def validate_no_still_a_risk_description?
    validate_no_still_a_risk_description == true
  end

end
