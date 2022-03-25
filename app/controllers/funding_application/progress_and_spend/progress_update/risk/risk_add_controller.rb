class FundingApplication::ProgressAndSpend::ProgressUpdate::Risk::RiskAddController < ApplicationController
  include FundingApplicationContext
  
  def show()

    @risk = @funding_application.arrears_journey_tracker.progress_update.progress_update_risk.build

  end

  def update()

    @risk = @funding_application.arrears_journey_tracker.progress_update.progress_update_risk.build

    assign_is_still_risk_description_param(@risk, params)

    toggle_validation(@risk, params)

    @risk.update(permitted_params(params))

    unless @risk.errors.any?

      # redirect to summary

    else

      render :show
    
    end

  end

  private

  # Returns the permitted params
  #
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def permitted_params(params)

    params.require(:progress_update_risk).permit(
      :description,
      :likelihood,
      :impact,
      :is_still_risk,
      :yes_still_a_risk_description,
      :no_still_a_risk_description,
      :is_still_risk_description
    )
  end

  # Uses a ternary to evaluate whether the applicant has indicated a
  # resolved or ongoing risk.
  # Then adds a new param for is_still_risk_description using either
  # yes_still_a_risk_description or no_still_a_risk_description
  #
  # @params [ProgressUpdateRisk] expiry_date 
  # @params [ActionController::Parameters] params Unfiltered params
  def assign_is_still_risk_description_param(risk, params)

    pp = permitted_params(params)

    pp[:is_still_risk] == true.to_s ? \
      params[:progress_update_risk][:is_still_risk_description] = \
        pp[:yes_still_a_risk_description] :\
          params[:progress_update_risk][:is_still_risk_description] = \
            pp[:no_still_a_risk_description]

  end

  # Evaluates whether the applicant has indicated a
  # resolved or ongoing risk.
  # Toggles appropriate validation so that either 
  # validate_yes_still_a_risk_description or 
  # validate_no_still_a_risk_description is validated
  #
  # @params [ProgressUpdateRisk] expiry_date 
  # @params [ActionController::Parameters] params Unfiltered params
  def toggle_validation(risk, params)

    pp = permitted_params(params)

    pp[:is_still_risk] == true.to_s ? \
      risk.validate_yes_still_a_risk_description = true :\
         risk.validate_no_still_a_risk_description = true

  end


end
  