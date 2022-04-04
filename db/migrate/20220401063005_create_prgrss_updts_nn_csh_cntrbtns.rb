class CreatePrgrssUpdtsNnCshCntrbtns < ActiveRecord::Migration[6.1]
  def change
    create_table :prgrss_updts_nn_csh_cntrbtns, id: :uuid do |t|
      t.references :progress_update, type: :uuid, null: true, foreign_key: true
      t.string :description
      t.integer :value
      t.timestamps
    end
  end
end
