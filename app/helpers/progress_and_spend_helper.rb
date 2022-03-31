module ProgressAndSpendHelper
  include SalesforceApi

  # Method responsible for orchestrating the retrieval of
  # additional grant conditions from Salesforce
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  def salesforce_additional_grant_conditions(funding_application)

    client = SalesforceApiClient.new

    case_id = funding_application.salesforce_case_id

    additional_grant_conditions =
      client.additional_grant_conditions \
        (funding_application.salesforce_case_id)

  end

  # Method responsible for getting project expiry date
  # from Salesforce.  Calls project_details on Salesforce
  # Api for code reuse. But could use a dedicated function
  # that only gets expiry if this is too slow.
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  # @return [String] result A grant expiry date
  def salesforce_project_expiry_date(funding_application)

    client = SalesforceApiClient.new

    case_id = funding_application.salesforce_case_id

    project_details =
      client.project_details \
        (funding_application.salesforce_case_id)

    grant_expiry_date = Date.parse(
      project_details.Grant_Expiry_Date__c 
    )

    result = grant_expiry_date.strftime("%d/%m/%Y")

  end

  # Validates and updates procurement model passed in - 
  # parsing date to correct modelformat, checks model valid
  # and calls update. Retruns the passed procurement model. 
  #
  # @param [ProgressUpdateProcurement] procurement An instance of
  #                                                                 ProgressUpdateProcurement
  # @return [ProgressUpdateProcurement] validated and updated procurement
  def validate_and_update_procurement(procurement)
    procurement.date_day = params[:progress_update_procurement][:date_day].to_i
    procurement.date_month = params[:progress_update_procurement][:date_month].to_i
    procurement.date_year = params[:progress_update_procurement][:date_year].to_i

    procurement.validate_date = true

    if procurement.valid?
      params[:progress_update_procurement][:date] = DateTime.new(
        procurement.date_year, 
        procurement.date_month, 
        procurement.date_day 
      )
    end

    procurement.validate_details = true

    procurement.update(get_params)
  end

  # Returns the permitted params
  #
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def risk_permitted_params(params)

    params.require(:progress_update_risk).permit(
      :id,
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
  # @params [ProgressUpdateRisk] risk
  # @params [ActionController::Parameters] params Unfiltered params
  def assign_is_still_risk_description_param(risk, params)

    pp = risk_permitted_params(params)

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
  # @params [ProgressUpdateRisk] risk
  # @params [ActionController::Parameters] params Unfiltered params
  def toggle_risk_validation(risk, params)

    pp = risk_permitted_params(params)

    pp[:is_still_risk] == true.to_s ? \
      risk.validate_yes_still_a_risk_description = true :\
         risk.validate_no_still_a_risk_description = true

  end

  # updates a given volunteer, afirms validation
  # and redirects to summary page if valid
  # or re-renders page to show validation errors
  #
  # @params [ProgressUpdateVolunteer] volunteer
  # @params [FundingAppplication] funding_app
  def update_validate_redirect_volunteer(volunteer, funding_app)
    volunteer.update(params.require(:progress_update_volunteer).permit(
        :id,
        :description,
        :hours
      )
    )

    if @volunteer.valid?
      redirect_to(
        funding_application_progress_and_spend_progress_update_volunteer_volunteer_summary_path(
            progress_update_id:
              funding_app.arrears_journey_tracker.progress_update.id
        )
      )
    else
      render :show
    end
  end
  
end
