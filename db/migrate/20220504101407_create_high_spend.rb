class CreateHighSpend < ActiveRecord::Migration[6.1]
  def change
    create_table :high_spends, id: :uuid do |t|
      t.references :payment_request, type: :uuid, null: true, foreign_key: true
      t.text :cost_heading
      t.text :description
      t.decimal :vat_amount
      t.decimal :amount
      t.datetime :date_of_spend
      t.integer :spend_threshold 
      t.timestamps
    end
  end
end
