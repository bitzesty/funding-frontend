class ProgressUpdateDigitalOutput < ApplicationRecord
  include GenericValidator

  self.table_name = 'prgrss_updts_digital_outputs'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  validates :description, presence: true

  validate do

    validate_length(
      :description,
      150,
      I18n.t(
        "activerecord.errors.models.progress_update_digital_" \
          "output.attributes.description.too_long",
        word_count: 150)
    )

  end

end
