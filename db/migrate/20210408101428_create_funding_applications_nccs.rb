class CreateFundingApplicationsNccs < ActiveRecord::Migration[6.1]
  def change
    create_table :funding_applications_nccs, id: :uuid do |t|
      t.references :funding_application, type: :uuid, null: false, foreign_key: true
      t.references :non_cash_contribution, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
  end
end
