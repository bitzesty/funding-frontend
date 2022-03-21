class FundingApplication::ProgressAndSpend::ProgressUpdate::AdditionalGrantConditionsController < ApplicationController
  include FundingApplicationContext  
  include ProgressAndSpendHelper

  def show()
    setup_additional_grant_conditions
    populate_check_boxes
  end

  def update()
  
    progress_update.update(get_params)

    are_checkbox_selections_correct?(get_params)

    if progress_update.errors.any?

      populate_check_boxes
      render :show

    else
      
      redirect_to(
        funding_application_progress_and_spend_progress_update_completion_date_path(
            progress_update_id:
              @funding_application.arrears_journey_tracker.progress_update.id
        )
      )

    end

  end


  private

  # Returns an instance of ProgressUpdate for current context
  # @return [ProgressUpdate]
  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end

  # Returns the permitted, nested params for :progress_update
  def get_params
    params.fetch(:progress_update, {}).permit(
      :no_progress_update,
      progress_update_additional_grant_condition_attributes:[
        :id,
        :progress,
        :salesforce_additional_grant_condition_id,
        :description,
        :entering_update
      ]
    )
  end

  # Calls additional_grant_conditions() - to get each additional grant
  # condition (aka - adc) from Salesforce.
  # It checks to see if a row for that adc has been entered on Postgres
  # already.  And if not, inserts a row for that adc, writing information
  # that an applicant can't change - like adc description and id.
  def setup_additional_grant_conditions

    salesforce_additional_grant_conditions(
      @funding_application
    ).each do |sf_adc|
  
      unless adc_already_in_postgres(sf_adc.Id)

        ffe_adc =   
          progress_update.progress_update_additional_grant_condition.create(
            description: sf_adc.Additional_Grant_Condition_Text__c,
            salesforce_additional_grant_condition_id: sf_adc.Id
          )

      end

    end

  end

  # true if an additional grant condition has been stored in pg
  # false if an additional grant condition not in pg yet
  #
  # @param [String] adc_id Salesforce Id for an additional grant 
  #                        condition record.
  # @return [Boolean] result true if pg row has already been stored
  def adc_already_in_postgres(adc_id)
    
    progress_update.progress_update_additional_grant_condition.include?(
         ProgressUpdateAdditionalGrantCondition.find_by(
           salesforce_additional_grant_condition_id: adc_id
           )
         )
   end
  
  # Should be caklled prior to show
  # Simply checks boxes when progress updates given
  # Does this by setting attr_accessor :entering_update
  def populate_check_boxes
    progress_update.progress_update_additional_grant_condition.each do |adc|
      adc.entering_update = adc.progress.present? || adc.entering_update == 'true'
    end
  end

  # Validation depends on form params and whichever
  # checkbox is selected. Given this, validation is more straighforward 
  # to implement in this controller.
  #
  # Method returns true if either the "I don't have an update" is 
  # selected or an update is chosen.
  # Method returns false if an update and "I don't have an update" are
  # chosen.  Or if nothing is chosen.
  #
  # @params [String] params Params from posted form
  # @return [Boolean] result True or False
  def are_checkbox_selections_correct?(params)
    
    result = false
    one_or_more_checkbox_selected = false
  
    progress_update.progress_update_additional_grant_condition.each do |adc|
      if adc.entering_update == 'true'
        one_or_more_checkbox_selected = true
        break
      end
    end

    if one_or_more_checkbox_selected != (params[:no_progress_update] == "true")
      result = true
    else
      result = false
      progress_update.errors.add(
        :progress_update_additional_grant_condition, 
        t("activerecord.errors.models.progress_update.attributes." \
          "progress_update_additional_grant_condition.checkbox_selection")
      )
    end

    result

  end
    

end
