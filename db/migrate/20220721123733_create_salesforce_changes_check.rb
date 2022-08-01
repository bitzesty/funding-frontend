class CreateSalesforceChangesCheck < ActiveRecord::Migration[6.1]
  def change
    create_table :salesforce_changes_checks, id: :uuid do |t|
      t.uuid :record_id
      t.text :record_type
      t.datetime :time_salesforce_checked
      t.timestamps
    end
  end
end
