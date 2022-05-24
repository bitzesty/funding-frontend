class AddSalesforceFormIdToCompletedArrearsJourneys < ActiveRecord::Migration[6.1]
  def change
    add_column :completed_arrears_journeys , :salesforce_form_id, :string
  end
end
