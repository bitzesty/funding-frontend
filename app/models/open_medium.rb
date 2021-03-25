class OpenMedium < ApplicationRecord

  self.implicit_order_column = 'created_at'

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'gp_open_medium'

  belongs_to :user
  belongs_to :funding_application, optional: true

  has_one :organisation, through: :user

end
