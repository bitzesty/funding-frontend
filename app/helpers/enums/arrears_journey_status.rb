module Enums::ArrearsJourneyStatus
  JOURNEY_STATUS = {
    not_started: 0,
    in_progress: 1,
    completed: 2,
  }
  
  def journey_status_string(value)
    JOURNEY_STATUS.key(value)
  end
end
