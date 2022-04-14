class CreatePrgrssUpdtsOutcomes < ActiveRecord::Migration[6.1]
  def change
    create_table :prgrss_updts_outcomes, id: :uuid do |t|
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.jsonb   :progress_updates
      t.timestamps
    end
  end
end
