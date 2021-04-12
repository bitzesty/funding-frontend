class AddVatToProjectCosts < ActiveRecord::Migration[6.1]
  def change
    add_column :project_costs, :vat_amount, :decimal
  end
end
