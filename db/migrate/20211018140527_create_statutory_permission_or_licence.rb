class CreateStatutoryPermissionOrLicence < ActiveRecord::Migration[6.1]
  def change
    create_table :statutory_permission_or_licences, id: :uuid do |t|
      t.jsonb   :details_json
      t.references :sfx_pts_payment, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
  end
end
