class ProgressUpdateStatutoryPermissionsLicence < ApplicationRecord
  include GenericValidator


  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'prgrss_updts_stttry_prmssns_lcncs'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  has_one_attached :progress_update_statutory_permissions_licence_file

  validate do

    validate_file_attached(
        :progress_update_statutory_permissions_licence_file,
        "Add a statutory permission or licence file"
    )

  end

end