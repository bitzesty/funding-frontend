class CreateFundingApplicationsLegalSigs < ActiveRecord::Migration[6.1]
  def change
    create_table :funding_applications_legal_sigs, id: :uuid do |t|
      t.references :funding_application, type: :uuid, null: false, foreign_key: true
      t.references :legal_signatory, type: :uuid, null: false, foreign_key: true
      t.datetime :signed_terms_submitted_on
      t.timestamps
    end
  end
end
