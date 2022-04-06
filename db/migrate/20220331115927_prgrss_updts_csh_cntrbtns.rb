class PrgrssUpdtsCshCntrbtns < ActiveRecord::Migration[6.1]
  def change
    create_table :prgrss_updts_csh_cntrbtns, id: :uuid do |t|
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.string :salesforce_project_income_id
      t.string :display_text
      t.integer :amount_expected
      t.integer :amount_received_so_far
      t.boolean :received_amount_expected
      t.boolean :will_receive_amount_expected
      t.datetime :date_amount_received
      t.string :reason_amount_expected_not_received
      t.timestamps
    end
  end
end

