class CreatePrgrssUpdtsDigitalOutput < ActiveRecord::Migration[6.1]
  def change
    create_table :prgrss_updts_digital_outputs, id: :uuid do |t|
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.text :description
      t.timestamps
    end
  end
end
