class ProgressUpdatePhoto < ApplicationRecord
  include GenericValidator

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'prgrss_updts_photos'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  has_one_attached :progress_updates_photo_files

  validate do

    validate_file_attached(
      :progress_updates_photo_files,
      I18n.t(
        "activerecord.errors.models.progress_update" \
          ".attributes.progress_update_photo.blank",
      ) 
    )

  end

end
