class CreateArrearsJourneyTracker < ActiveRecord::Migration[6.1]
  def change
    create_table :arrears_journey_trackers, id: :uuid do |t|
      t.references :funding_application, type: :uuid, null: false, foreign_key: true
      t.references :payment_request, type: :uuid, null: true, foreign_key: true
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.timestamps
    end
  end
end
