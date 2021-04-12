class FundingApplicationsCost < ApplicationRecord
  belongs_to :funding_application
  belongs_to :project_cost
end
