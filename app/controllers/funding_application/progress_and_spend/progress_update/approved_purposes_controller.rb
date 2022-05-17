# Stores the JSONB data as follows:
# {
# 	"boosting_economy": "",
# 	"developing_skills": "",
# 	"greater_wellbeing": "",
# 	"learning_heritage": "",
# 	"explaining_heritage": "",
# 	"improving_condition": "",
# 	"making_better_place": "",
# 	"improving_resilience": ""
# }
#
class FundingApplication::ProgressAndSpend::ProgressUpdate::ApprovedPurposesController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper
  include Enums::ArrearsJourneyStatus
  
    def show()

        setup_approved_purposes
        populate_check_boxes

    end
  
    def update()

      progress_update.update(permitted_params(params))

      are_checkbox_selections_correct?(permitted_params(params))

      if progress_update.errors.any?

        populate_check_boxes
        render :show
  
      else
  
        remove_purposes_not_selected_for_update
  
        update_json(
          progress_update.answers_json,
          progress_update.no_progress_update == 'true'
        )
        
        redirect_to(
          funding_application_progress_and_spend_progress_update_demographic_path(
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


    # Calls salesforce_approved_purposes function in ProgressAndSpendHelper
    # to get approved purposes.
    # It checks to see if a row for that ap has been entered on Postgres
    # already.  And if not, inserts a row for that ap, writing information
    # that an applicant can't change - like ap description and id.
    def setup_approved_purposes

      salesforce_approved_purposes(
        @funding_application
      ).each do |sf_ap|

        unless ap_already_in_postgres(sf_ap.Id)

          progress_update.progress_update_approved_purpose.create(
            description: sf_ap.Approved_Purposes__c,
            salesforce_approved_purpose_id: sf_ap.Id
          )

        end

      end

    end

    # true if an approved purpose has been stored in pg
    # false if an approved purpose not in pg yet
    #
    # @param [String] ap_id Salesforce Id for an approved purpose record
    # @return [Boolean] result true if pg row has already been stored
    def ap_already_in_postgres(ap_id)

      progress_update.progress_update_approved_purpose.include?(
          ProgressUpdateApprovedPurpose.find_by(
            salesforce_approved_purpose_id: ap_id
            )
          )
    end

    # Should be called prior to show
    # Simply checks boxes when progress updates provided by the applicant
    # Does this by setting attr_accessor :entering_update
    def populate_check_boxes

      progress_update.progress_update_approved_purpose.each do |ap|
        ap.entering_update = ap.progress.present? || ap.entering_update == 'true'
      end

      if progress_update.answers_json['approved_purpose'].has_key?(
        'no_progress_update'
      )

        progress_update.no_progress_update = \
          progress_update.answers_json['approved_purpose']\
            ['no_progress_update'] if progress_update.no_progress_update.nil?

      end

    end

    # Returns the permitted params
    #
    # @params [ActionController::Parameters] params A hash of params
    # @return [ActionController::Parameters] params A hash of filtered params
    def permitted_params(params)
      params.fetch(:progress_update, {}).permit(
        :no_progress_update,
        progress_update_approved_purpose_attributes:[
          :id,
          :progress,
          :entering_update
        ]
      )
    end

    # Validation depends on form params and whichever
    # checkbox is selected. Given this, validation is more straightforward
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
    
      progress_update.progress_update_approved_purpose.each do |ap|
        if ap.entering_update == 'true'
          one_or_more_checkbox_selected = true
          break
        end
      end

      if one_or_more_checkbox_selected != (params[:no_progress_update] == "true")
        result = true
      else
        result = false
        progress_update.errors.add(
          :progress_update_approved_purpose, 
          t("activerecord.errors.models.progress_update.attributes." \
            "progress_update_approved_purpose.checkbox_selection")
        )
      end

      result

    end
    
    # Called at the end of update.
    # Removes any ProgressUpdateApprovedPurpose
    # instances that have no progress updates against them.
    def remove_purposes_not_selected_for_update

      progress_update.progress_update_approved_purpose.each do |ap|
        ap.destroy if ap.entering_update == 'false'
      end

    end

    # updates json with a new key value pair
    # In this case, whether the grant expiry date is correct.
    #
    # Then sets the journey status json
    #
    # @params [jsonb] answers_json Json containing journey answers
    # @params [Boolean] answer Either true or false
    def update_json(answers_json, answer)

      answers_json['approved_purpose']['no_progress_update'] = answer
      progress_update.answers_json = answers_json

      unless @funding_application.arrears_journey_tracker.progress_update.\
        answers_json['journey_status']['approved_purposes'] == \
          JOURNEY_STATUS[:completed]

        @funding_application.arrears_journey_tracker.progress_update.\
          answers_json['journey_status']['approved_purposes'] \
            = JOURNEY_STATUS[:in_progress] 
      
      end

      progress_update.save
      
    end

  
  end
