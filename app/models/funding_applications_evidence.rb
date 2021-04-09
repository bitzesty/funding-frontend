class FundingApplicationsEvidence < ApplicationRecord
  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'funding_applications_eos'
  belongs_to :funding_application
  belongs_to :evidence_of_support
end
