class FundingApplication::ProgressAndSpend::PreviousSubmissions::SubmissionSummary::PaymentsSubmissionController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show

    payment_request =
      @funding_application.payment_requests.find(params[:payment_request_id])
  
    unless payment_request.low_spend.empty?

      @low_spend = payment_request.low_spend

      @low_spend_update_total =
        @low_spend.sum {|ls| ls.total_amount + ls.vat_amount}

      @low_spend_table_heading =
        t(
          "progress_and_spend.previous_submissions.submission_summary."\
            "payments_summary.spend_under",
          spend_amount: @low_spend.first.spend_threshold
        )

    end

    unless payment_request.high_spend.empty?

      @high_spend = payment_request.high_spend

      @high_spend_update_total =
        @high_spend.sum {|hs| hs.amount + hs.vat_amount}

      @high_spend_table_heading =
        t(
          "progress_and_spend.previous_submissions.submission_summary."\
            "payments_summary.spend_over",
          spend_amount: @high_spend.first.spend_threshold
        )
    end

  end

  def update
    redirect_to funding_application_progress_and_spend_previous_submissions_previously_submitted_path(
      completed_arrears_journey_id: params[:completed_arrears_journey_id] )
  end
end
