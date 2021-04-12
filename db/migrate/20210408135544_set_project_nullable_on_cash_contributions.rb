class SetProjectNullableOnCashContributions < ActiveRecord::Migration[6.1]
  def change
    change_column_null :cash_contributions, :project_id, true
  end
end
