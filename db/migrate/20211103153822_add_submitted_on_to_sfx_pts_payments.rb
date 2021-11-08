class AddSubmittedOnToSfxPtsPayments < ActiveRecord::Migration[6.1]
  def change
    add_column :sfx_pts_payments, :submitted_on, :datetime
  end
end
