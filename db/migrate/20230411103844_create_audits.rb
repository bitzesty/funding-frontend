class CreateAudits < ActiveRecord::Migration[6.1]
  def change
    create_table :audits, id: :uuid do |t|

      t.integer :user_id
      t.string :user_name
      t.string :user_email
      t.integer :user_role
      t.string :record_type
      t.string :record_id
      t.integer :action
      t.boolean :action_successful
      t.jsonb :record_changes
      t.date :redact_date
      t.uuid :request_id
      t.timestamps

    end
  end
end
