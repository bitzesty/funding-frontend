class ArrearsJourneyTracker < ApplicationRecord
  belongs_to :funding_application
  belongs_to :payment_request, optional: true
  belongs_to :progress_update, optional: true
end