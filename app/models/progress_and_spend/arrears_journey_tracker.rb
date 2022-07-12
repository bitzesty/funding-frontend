class ArrearsJourneyTracker < ApplicationRecord
  belongs_to :funding_application
  belongs_to :payment_request, optional: true
  belongs_to :progress_update, optional: true

  attr_accessor :get_payment
  attr_accessor :give_project_update

  attr_accessor :validate_journey_selection

  validate :validate_journey_selection_presence

  private

  def validate_journey_selection_presence
    if validate_journey_selection
      unless get_payment == "true" ||  give_project_update == "true"
        errors.add(
          :base, 
          I18n.t("progress_and_spend.select_journey.please_select")
        )
      end
    end
  end

end