class CreatePrgrssUpdtsPrcrmntEvidence < ActiveRecord::Migration[6.1]
  def change
    create_table :prgrss_updts_prcrmnt_evidences, id: :uuid do |t|
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.timestamps
    end
  end
end
