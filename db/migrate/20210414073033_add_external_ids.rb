class AddExternalIds < ActiveRecord::Migration[6.1]
  def change
    add_column :project_costs, :salesforce_external_id, :string
    add_column :volunteers, :salesforce_external_id, :string
    add_column :non_cash_contributions, :salesforce_external_id, :string
    add_column :cash_contributions, :salesforce_external_id, :string
  end
end
