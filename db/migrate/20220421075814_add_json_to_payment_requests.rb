class AddJsonToPaymentRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :payment_requests, :answers_json, :jsonb
  end
end
