class CreateProgressUpdate < ActiveRecord::Migration[6.1]
  def change
    create_table :progress_updates, id: :uuid do |t|
      t.datetime :submitted_on
      t.timestamps
    end
  end
end
