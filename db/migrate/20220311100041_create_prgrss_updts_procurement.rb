class CreatePrgrssUpdtsProcurement < ActiveRecord::Migration[6.1]
  def change
    create_table :prgrss_updts_procurements, id: :uuid do |t|
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.string :name
      t.text :description
      t.datetime :date
      t.integer :amount
      t.boolean :lowest_tender
      t.text :supplier_justification
      t.timestamps
    end
  end
end
