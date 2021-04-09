class SetProjectNullableOnNonCashContributions < ActiveRecord::Migration[6.1]
  def change
    change_column_null :non_cash_contributions, :project_id, true
  end
end
