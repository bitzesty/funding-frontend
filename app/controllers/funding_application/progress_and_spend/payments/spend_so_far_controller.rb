class FundingApplication::ProgressAndSpend::Payments::SpendSoFarController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  
  def show()

    @payment_request =
      @funding_application.arrears_journey_tracker.payment_request

    redirect_to(
      funding_application_progress_and_spend_payments_what_spend_path(
        payment_request_id: @payment_request.id
      )
    ) if first_time_on_this_journey?(@payment_request)


    initialise_instance_vars unless \
      first_time_on_this_journey?(@payment_request)

  end

  def update()

    @payment_request =
      @funding_application.arrears_journey_tracker.payment_request

    @payment_request.validate_add_or_change_spend = true

    @payment_request.update(required_params(params))

    unless @payment_request.errors.any?

      redirect_to(
        funding_application_progress_and_spend_payments_what_spend_path(
          payment_request_id: @payment_request.id
        )
      ) if @payment_request.add_or_change_spend == 'true'

      if @payment_request.add_or_change_spend == 'false'

        redirect_to \
          funding_application_progress_and_spend_progress_and_spend_tasks_path(
        )

        set_arrears_payment_status(JOURNEY_STATUS[:completed])

      end
      
    else

      initialise_instance_vars
      render :show

    end
  
  end

  private

  # Returns the required params.
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def required_params(params)
    params.fetch(:payment_request, {}).permit(
      :add_or_change_spend
    )
  end

  def initialise_instance_vars

    @spend_threshold = get_spend_threshold(@funding_application)

    # prepare instance variables for low spend summary table
    @low_spend = @payment_request.low_spend

    @low_spend_update_total = @low_spend.sum {|ls| ls.total_amount + ls.vat_amount}

    @low_spend_table_heading =
      t(
        'progress_and_spend.payments.low_spend_summary.page_heading',
        spend_amount: @spend_threshold
      )

    # prepare instance variables for high spend summary table
    remove_high_spends_with_no_file(@payment_request) if \
      @payment_request.high_spend.present?

    @high_spend = @payment_request.high_spend

    @high_spend_update_total = @high_spend.sum {|hs| hs.amount + hs.vat_amount}

    @high_spend_table_heading =
    t(
      'progress_and_spend.payments.high_spend_summary.page_heading',
      spend_amount: @spend_threshold
    )

    # toggle the edit/delete links off
    @show_change_links = false
  end

  # If its the first time this user has been through the spend
  # journey - then return true
  #
  # @param [PaymentRequest] payment_request
  # @return [Boolean] status == :not_started True if 1st time
  def first_time_on_this_journey?(payment_request)

    status =
      journey_status_string(
        payment_request.answers_json['arrears_journey']['status']
    )

    status == :not_started

  end

end
