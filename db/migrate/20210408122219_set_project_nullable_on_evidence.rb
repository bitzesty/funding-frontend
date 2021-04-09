class SetProjectNullableOnEvidence < ActiveRecord::Migration[6.1]
  def change
    change_column_null :evidence_of_support, :project_id, true
  end
end
