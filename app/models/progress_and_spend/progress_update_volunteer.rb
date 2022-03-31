class ProgressUpdateVolunteer < ApplicationRecord
  include GenericValidator


  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'prgrss_updts_volunteers'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  validates :description, presence:true

  validates :hours, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than: 2147483647
  }

  validate do

    validate_length(
      :description,
      50,
      I18n.t(
        "activerecord.errors.models.progress_update_" \
          "volunteer.attributes.description.too_long",
        word_count: 50)
    )
  end

end