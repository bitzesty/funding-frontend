class AddApplicationTypesToSfxPtsPayments < ActiveRecord::Migration[6.1]
  def change
    add_column :sfx_pts_payments, :application_type, :integer
  end
end
