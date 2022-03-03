class AddAnswersToProgressUpdate < ActiveRecord::Migration[6.1]
  def change
    add_column :progress_updates, :answers_json, :jsonb
  end
end
