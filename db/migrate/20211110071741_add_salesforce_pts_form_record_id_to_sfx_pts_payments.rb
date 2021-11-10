class AddSalesforcePtsFormRecordIdToSfxPtsPayments < ActiveRecord::Migration[6.1]
  def change
    add_column :sfx_pts_payments, :salesforce_pts_form_record_id, :string
  end
end
