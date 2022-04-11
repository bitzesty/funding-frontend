class CreatePrgrssUpdtsDemographic < ActiveRecord::Migration[6.1]
  def change
    create_table :prgrss_updts_demographics, id: :uuid do |t|
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.text :explanation
      t.timestamps
    end
  end
end
