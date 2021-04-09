class FundingApplicationsNcc < ApplicationRecord
  belongs_to :funding_application
  belongs_to :non_cash_contribution
  end
