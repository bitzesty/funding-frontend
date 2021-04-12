class SetProjectNullableOnCosts < ActiveRecord::Migration[6.1]
  def change
    change_column_null :project_costs, :project_id, true
  end
end
