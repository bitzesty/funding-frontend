class AddAgreementSubmittedOnToFundingApplication < ActiveRecord::Migration[6.1]
  def change
    add_column :funding_applications, :agreement_submitted_on, :datetime
  end
end
