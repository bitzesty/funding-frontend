class DropSpends < ActiveRecord::Migration[6.1]
  def change
    drop_table :payment_requests_spends
    drop_table :spends
  end
end
