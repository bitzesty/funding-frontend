class AddSubmittedOnToPaymentRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :payment_requests, :submitted_on, :datetime
  end
end
