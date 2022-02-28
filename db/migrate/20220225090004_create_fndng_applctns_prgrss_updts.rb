class CreateFndngApplctnsPrgrssUpdts < ActiveRecord::Migration[6.1]
  def change
    create_table :fndng_applctns_prgrss_updts, id: :uuid do |t|
      t.references :funding_application, type: :uuid, null: false, foreign_key: true
      t.references :progress_update, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
  end
end
