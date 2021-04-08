class CreateHeritageDesignations < ActiveRecord::Migration[6.1]
  def change
    create_table :heritage_designations, id: :uuid do |t|
      t.string :designation
      t.timestamps
    end
  end
end
