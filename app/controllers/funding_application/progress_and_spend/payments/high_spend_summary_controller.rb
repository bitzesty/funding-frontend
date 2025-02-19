class FundingApplication::ProgressAndSpend::Payments::HighSpendSummaryController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  
    def show()

      payment_request =
        @funding_application.arrears_journey_tracker.payment_request

      remove_high_spends_with_no_file(payment_request) if \
        payment_request.high_spend.present?

      @spend_threshold = get_high_spend_threshold_from_json(payment_request, @funding_application)
      
      @high_spend = payment_request.high_spend

      @high_spend_update_total = @high_spend.sum {|hs| hs.amount + hs.vat_amount}

      @high_spend_table_heading =
      t(
        'progress_and_spend.payments.high_spend_summary.your_project_spend',
        spend_amount: @spend_threshold
      )

      @show_change_links = true

    end
  
    def update()

      payment_request =
        @funding_application.arrears_journey_tracker.payment_request

      # Spend threshold used by validation, which is why set here.
      @spend_threshold = get_high_spend_threshold_from_json(payment_request, @funding_application)
      payment_request.validate_add_another_high_spend = true

      payment_request.update(fetched_params(params))

      unless payment_request.errors.any?

        if payment_request.add_another_high_spend.to_s == 'false'

          remove_spend_journey_from_todo_array(
            @funding_application.arrears_journey_tracker.payment_request
          )

          spend_journey_redirector(
            payment_request.answers_json,
            payment_request.high_spend.present?,
            payment_request.low_spend.present?
          )

       elsif payment_request.add_another_high_spend.to_s == 'true'

          redirect_to(
            funding_application_progress_and_spend_payments_high_spend_add_path
          )

       end

      else

        @high_spend = payment_request.high_spend

        @high_spend_update_total = @high_spend.sum {|hs| hs.amount + hs.vat_amount}

        @high_spend_table_heading =
          t(
            'progress_and_spend.payments.high_spend_summary.your_project_spend',
            spend_amount: @spend_threshold
          )

        @show_change_links = true

        render :show

      end

    end

    # For released 40% payment forms, some files may already exist in Salesforce.
    # Ids for these live in the salesforce_content_document_ids column of high spends
    # Loop through these Ids and call the active job to delete the files.
    # Some of the file Ids may no longer exist, because IMs have manually deleted the
    # files, or the forms may be released multiple times.
    def delete()

      logger.info(
        'Deleting high_spend with id: ' \
          "#{params[:high_spend_id]} from payment_request ID: " \
            "#{params[:payment_request_id]}"
      )


      HighSpend.find(params[:high_spend_id])&.salesforce_content_document_ids&.each do |file_id|

        DeleteDocumentJob.perform_later(file_id)

      end

      HighSpend.destroy(params[:high_spend_id])

      redirect_to(
        funding_application_progress_and_spend_payments_high_spend_summary_path
        )

    end

    private

    # Returns the fetched params.
    # @params [ActionController::Parameters] params A hash of params
    # @return [ActionController::Parameters] params A hash of filtered params
    def fetched_params(params)
      params.fetch(:payment_request, {}).permit(
        :add_another_high_spend
      )
    end

  end
