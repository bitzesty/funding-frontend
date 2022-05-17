class CreatePrgrssUpdtsFndngAcknwldgmnt < ActiveRecord::Migration[6.1]
  def change
    create_table :prgrss_updts_fndng_acknwldgmnts, id: :uuid do |t|
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.jsonb   :acknowledgements
      t.timestamps
    end
  end
end
