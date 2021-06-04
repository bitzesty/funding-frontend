class CreateAgreements < ActiveRecord::Migration[6.1]
  def change
    create_table :agreements, id: :uuid do |t|
      t.references :funding_application, type: :uuid, null: false, foreign_key: true
      t.datetime :grant_agreed_at
      t.datetime :terms_agreed_at
      t.timestamps
    end
  end
end
