class ProgressUpdateProcurement < ApplicationRecord
  include GenericValidator

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'prgrss_updts_procurements'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  attr_accessor :name
  attr_accessor :description
  attr_accessor :date
  attr_accessor :amount
  attr_accessor :lowest_tender
  attr_accessor :supplier_justification

end
