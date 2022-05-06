class FundingApplication::ProgressAndSpend::PreviousSubmissions::SubmissionSummary::PaymentsSubmissionController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show

    payment_request =
    @funding_application.payment_requests.find(params[:payment_request_id])
  
    @low_spend = payment_request.low_spend

    @update_total = @low_spend.sum {|ls| ls.total_amount + ls.vat_amount}

  end

  def update
    redirect_to funding_application_progress_and_spend_previous_submissions_previously_submitted_path(
      completed_arrears_journey_id: params[:completed_arrears_journey_id] )
  end
end
