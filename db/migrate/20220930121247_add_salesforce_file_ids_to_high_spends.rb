class AddSalesforceFileIdsToHighSpends < ActiveRecord::Migration[6.1]
  def change
    add_column :high_spends, :salesforce_content_document_ids, :text, array: true
  end
end
