class CreateLowSpend < ActiveRecord::Migration[6.1]
  def change
    create_table :low_spends, id: :uuid do |t|
      t.references :payment_request, type: :uuid, null: true, foreign_key: true
      t.text :cost_heading
      t.decimal :vat_amount
      t.decimal :total_amount
      t.integer :spend_threshold 
      t.timestamps
    end
  end
end
