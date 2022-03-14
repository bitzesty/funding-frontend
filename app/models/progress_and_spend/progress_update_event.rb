class ProgressUpdateEvent < ApplicationRecord
  include GenericValidator

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'prgrss_updts_events'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  has_one_attached :progress_updates_event_files

  validate do

    validate_file_attached(
        :progress_updates_event_files,
        "Add an event file"
    )

  end

end
