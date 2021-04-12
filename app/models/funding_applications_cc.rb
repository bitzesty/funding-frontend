class FundingApplicationsCc < ApplicationRecord
  belongs_to :funding_application
  belongs_to :cash_contribution
end
