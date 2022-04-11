class ProgressUpdateDemographic < ApplicationRecord
  include GenericValidator

  self.table_name = 'prgrss_updts_demographics'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  validates :explanation, presence: true

  validate do

    validate_length(
      :explanation,
      300,
      I18n.t(
        "activerecord.errors.models.progress_update_demographic" \
          ".attributes.explanation.too_long",
        word_count: 300)
    )

  end

end
