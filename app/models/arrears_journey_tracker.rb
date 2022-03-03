class ArrearsJourneyTracker < ApplicationRecord
  belongs_to :funding_application
  belongs_to :payment_request
  belongs_to :progress_update
end