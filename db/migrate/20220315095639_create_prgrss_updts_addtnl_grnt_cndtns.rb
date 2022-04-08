class CreatePrgrssUpdtsAddtnlGrntCndtns < ActiveRecord::Migration[6.1]
  def change
    create_table :prgrss_updts_addtnl_grnt_cndtns, id: :uuid do |t|
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.string :progress
      t.string :description
      t.string :salesforce_additional_grant_condition_id
      t.timestamps
    end
  end
end
