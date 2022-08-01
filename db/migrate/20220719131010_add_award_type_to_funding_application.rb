class AddAwardTypeToFundingApplication < ActiveRecord::Migration[6.1]
  def change
    add_column :funding_applications, :award_type, :integer
  end
end
