class CreateSfxPtsPayments < ActiveRecord::Migration[6.1]
  def change
    create_table :sfx_pts_payments, id: :uuid do |t|
      t.text :salesforce_case_id
      t.string :email_address
      t.jsonb   :pts_answers_json
      t.timestamps
    end
  end
end
