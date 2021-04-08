class CreateGpOpenMediumHeritageDsgntns < ActiveRecord::Migration[6.1]
  def change
    create_table :gp_o_m_heritage_dsgntns, id: :uuid do |t|
      t.references :gp_open_medium, type: :uuid, null: false, foreign_key: { to_table: 'gp_open_medium' }
      t.references :heritage_designation, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
  end
end
