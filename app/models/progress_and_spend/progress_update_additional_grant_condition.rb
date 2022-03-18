class ProgressUpdateAdditionalGrantCondition < ApplicationRecord
  include GenericValidator

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'prgrss_updts_addtnl_grnt_cndtns'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  attr_accessor :entering_update

  validates :progress, presence: true, if: :validate_progress_presence

  validate do

    validate_length(
      :progress,
      300,
      I18n.t(
        "activerecord.errors.models.progress_update_additional_" \
          "grant_condition.attributes.progress.too_long",
        word_count: 300)
    )

  end

  def validate_progress_presence
    self.entering_update == 'true'
  end

end
