class ArrearsJourneyTracker < ApplicationRecord
  belongs_to :funding_application
  has_one :payment_request
  has_one :progress_update
end