class OpenMedium < ApplicationRecord
  include ActiveModel::Validations, GenericValidator

  self.implicit_order_column = 'created_at'

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'gp_open_medium'

  belongs_to :user
  belongs_to :funding_application, optional: true

  has_one :organisation, through: :user

  attr_accessor :validate_received_advice_description
  attr_accessor :validate_title

  validates :project_title, presence: true, length: { maximum: 255 }, if: :validate_title?

  validate do

    validate_length(
      :received_advice_description,
      500,
      I18n.t('activerecord.errors.models.open_medium.attributes.received_advice_description.too_long', word_count: 500)
    ) if validate_received_advice_description?

  end

  def validate_received_advice_description?
    validate_received_advice_description == true
  end

  def validate_title?
    validate_title == true
  end

end
