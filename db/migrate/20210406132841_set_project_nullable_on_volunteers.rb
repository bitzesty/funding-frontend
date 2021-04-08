class SetProjectNullableOnVolunteers < ActiveRecord::Migration[6.1]
  def change
    change_column_null :volunteers, :project_id, true
  end
end
