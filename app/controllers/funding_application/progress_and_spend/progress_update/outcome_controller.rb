class FundingApplication::ProgressAndSpend::ProgressUpdate::OutcomeController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()
    @outcomes = get_outcomes
  end

  def update()

    @outcomes = get_outcomes

    @outcomes.progress_updates = build_outcomes_hash_from_params(params)

    @outcomes.validate_progress_updates = true

    if @outcomes.valid?

      @outcomes.save!

      redirect_to(
        funding_application_progress_and_spend_progress_update_digital_outputs_question_path(
          progress_update_id:  \
            @funding_application.arrears_journey_tracker.progress_update.id
        )
      )

    else
      render :show
    end

  end

  private

  # Returns an instance of ProgressUpdate for current context
  # @return [ProgressUpdate]
  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end

  # Gets an instance of progress_update_outcome
  # Checks to see if an instance exists, and returns if so.
  #
  # If no instance of progress_update_outcome yet, gets a hash of 
  # outcomes associated with a project from Salesforce
  #
  # If this hash is empty, then the user is redirected to the check outcome
  # answers page, as no outcome updates are needed.
  #
  # If hash not empty, an instance of progress_update_outcome is created and 
  # populated with its progress_updates field containing the hash.
  #
  # The progress_updates field will be populated using outcome/show.html.erb.
  #
  # @return [ProgressUpdateOutcome] Either a new or existing instance.
  def get_outcomes

    if progress_update.progress_update_outcome.first.nil?

      outcomes_hash = get_outcomes_hash_from_salesforce(
        @funding_application.salesforce_case_id
      )

      unless outcomes_hash.empty?

        progress_update.progress_update_outcome.create(
          progress_updates: outcomes_hash

        )

      else

        logger.info("no outcome updates required for " \
          "funding application: #{@funding_application.id}.")

        redirect_to(
          funding_application_progress_and_spend_progress_update_digital_outputs_question_path(
            progress_update_id:  \
              @funding_application.arrears_journey_tracker.progress_update.id
          )
        )

      end

    end

    progress_update.progress_update_outcome.first

  end

end
