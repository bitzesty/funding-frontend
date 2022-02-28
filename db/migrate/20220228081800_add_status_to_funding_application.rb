class AddStatusToFundingApplication < ActiveRecord::Migration[6.1]
  def change
    add_column :funding_applications, :status, :integer
  end
end
