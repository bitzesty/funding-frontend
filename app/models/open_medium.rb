class OpenMedium < ApplicationRecord
  include ActiveModel::Validations, GenericValidator

  self.implicit_order_column = 'created_at'

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'gp_open_medium'

  belongs_to :user
  belongs_to :funding_application, optional: true

  has_one :organisation, through: :user

  attr_accessor :validate_received_advice_description

  validate do

    validate_length(
      :received_advice_description,
      500,
      I18n.t('activerecord.errors.models.gp_open_medium.attributes.received_advice_description.too_long', word_count: 500)
    ) if validate_received_advice_description?

  end

  def validate_received_advice_description?
    validate_received_advice_description == true
  end

end
