class CreatePrgrssUpdtsStttryPrmssnsLcncs < ActiveRecord::Migration[6.1]
  def change
    create_table :prgrss_updts_stttry_prmssns_lcncs, id: :uuid do |t|
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.timestamps
    end
  end
end
