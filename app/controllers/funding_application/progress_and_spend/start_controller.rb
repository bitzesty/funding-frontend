class FundingApplication::ProgressAndSpend::StartController < ApplicationController
include FundingApplicationContext
include FundingApplicationHelper

  def show()

    if @funding_application.dev_to_100k?
      @fifty_perc_payment_amount = get_agreed_project_costs_dev(
        @funding_application.salesforce_case_id
      )/ 2
    else
      @fifty_perc_payment_amount = get_total_project_costs(
        @funding_application.salesforce_case_id
      ) / 2
    end

  end

  def update()

    @funding_application.arrears_journey_tracker =  
      ArrearsJourneyTracker.create(
        funding_application_id: @funding_application.id
      ) unless @funding_application.arrears_journey_tracker.present?

    if @funding_application.arrears_journey_tracker.payment_request_id.blank? &&
      @funding_application.arrears_journey_tracker.progress_update_id.blank?
        redirect_to funding_application_progress_and_spend_select_journey_path()
    else
      redirect_to \
        funding_application_progress_and_spend_progress_and_spend_tasks_path()
    end

  end

end
