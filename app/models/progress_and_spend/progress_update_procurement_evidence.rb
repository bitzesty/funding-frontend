class ProgressUpdateProcurementEvidence < ApplicationRecord
  include GenericValidator


  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'prgrss_updts_prcrmnt_evidences'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  has_one_attached :progress_updates_procurement_evidence_file

  validate do

    validate_file_attached(
        :progress_updates_procurement_evidence_file,
        "Add a procuments evidence file"
    )

  end

end
