class CreateFundingApplicationsEos < ActiveRecord::Migration[6.1]
  def change
    create_table :funding_applications_eos, id: :uuid do |t|
      t.references :funding_application, type: :uuid, null: false, foreign_key: true
      t.references :evidence_of_support, type: :uuid, null: false, foreign_key: { to_table: 'evidence_of_support' }
      t.timestamps
    end
  end
end
