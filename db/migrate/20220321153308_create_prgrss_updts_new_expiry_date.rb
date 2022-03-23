class CreatePrgrssUpdtsNewExpiryDate < ActiveRecord::Migration[6.1]
  def change
    create_table :prgrss_updts_new_expiry_date, id: :uuid do |t|
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.text :description
      t.datetime :full_date
      t.timestamps
    end
  end
end
