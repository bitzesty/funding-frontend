class FundingApplication::ProgressAndSpend::ProgressUpdate::Risk::RiskRegisterController < ApplicationController
  include FundingApplicationContext

  def show()
    get_attachments
    initialize_view
  end

  def update()

    progress_update.validate_has_risk_register = true

    progress_update.has_risk_register =
      params[:progress_update].nil? ? nil :
        params[:progress_update][:has_risk_register]

    if progress_update.has_risk_register == "true"
      progress_update.validate_progress_update_risk_register = true
    end

    if params.has_key?(:save_and_continue_button)

      update_json(
        progress_update.answers_json,
        progress_update.has_risk_register
      )

      if progress_update.errors.any?

        rerender

      else

        if progress_update.has_risk_register == "true"

          redirect_to(
            funding_application_progress_and_spend_progress_update_cash_contribution_cash_contribution_question_path(
              progress_update_id:  \
                @funding_application.arrears_journey_tracker.progress_update.id
            )
          )

        else

          redirect_to(
            funding_application_progress_and_spend_progress_update_risk_risk_add_path(
              progress_update_id:  \
                @funding_application.arrears_journey_tracker.progress_update.id
            )
          )

        end

      end

    end

    # Form submitted to delete a file.
    if params.has_key?(:delete_file_button)
      delete(params[:delete_file_button])
    end

    # Form submitted to add a file.
    if params.has_key?(:add_file_button)

      update_json(
        progress_update.answers_json,
        progress_update.has_risk_register
      )

      progress_update.update( get_params )
      rerender
    end
  end

  private

  def initialize_view()
    if  progress_update.answers_json['risk']\
      ['has_risk_register'] == true.to_s
      progress_update.has_risk_register = true.to_s
    elsif  progress_update.answers_json['risk']\
      ['has_risk_register'] == false.to_s
      progress_update.has_risk_register = false.to_s
    end
  end

  def rerender()
      initialize_view
      get_attachments
      render :show
  end

  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end

  def get_attachments
    @attachments_hash = Hash.new
    @funding_application.arrears_journey_tracker.progress_update
      .progress_update_risk_register&.map{|attachment| \
          @attachments_hash[attachment.id] = \
            attachment.progress_update_risk_register_file_blob}
  end

  def delete(risk_register_id)

    update_json(
      progress_update.answers_json,
      progress_update.has_risk_register
    )

    risk_register =
      @funding_application.arrears_journey_tracker.progress_update.\
        progress_update_risk_register.find(
          risk_register_id
        )
    risk_register.destroy

    logger.info "Removed progress_update_risk_register "
      "with id: #{risk_register_id} for progress update " \
        "#{@funding_application.arrears_journey_tracker.progress_update.id}"

    redirect_to(
      funding_application_progress_and_spend_progress_update_risk_risk_register_path(
          progress_update_id:  \
            @funding_application.arrears_journey_tracker.progress_update.id
        )
    )

  end

  def get_params
    params.fetch(:progress_update, {}).permit(
      progress_update_risk_register_attributes:[
        :progress_update_risk_register_file
      ]
    )
  end

  # updates json with a new key value pair
  # In this case, whether the grant expiry date is correct.
  # @params [jsonb] answers_json Json containing journey answers
  # @params [Boolean] answer Either true or false
  def update_json(answers_json, answer)
    answers_json['risk']['has_risk_register'] = answer
    progress_update.answers_json = answers_json
    progress_update.save
  end

end
