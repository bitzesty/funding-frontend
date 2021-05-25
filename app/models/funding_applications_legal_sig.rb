class FundingApplicationsLegalSig < ApplicationRecord
  belongs_to :funding_application
  belongs_to :legal_signatory
end