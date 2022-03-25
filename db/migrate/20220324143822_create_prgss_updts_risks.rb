class CreatePrgssUpdtsRisks < ActiveRecord::Migration[6.1]
  def change
    create_table :prgrss_updts_risks, id: :uuid do |t|
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.string :description
      t.integer :likelihood
      t.integer :impact
      t.boolean :is_still_risk
      t.string :is_still_risk_description
      t.timestamps
    end
  end
end
