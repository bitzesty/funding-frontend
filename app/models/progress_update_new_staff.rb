class ProgressUpdateNewStaff < ApplicationRecord
  include GenericValidator

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'prgrss_updts_new_staffs'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  has_one_attached :progress_updates_new_staff_files

  validate do

    validate_file_attached(
        :progress_updates_new_staff_files,
        "Add a new staff file"
    )

  end

end
