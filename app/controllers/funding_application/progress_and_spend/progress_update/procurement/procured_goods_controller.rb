class FundingApplication::ProgressAndSpend::ProgressUpdate::Procurement::ProcuredGoodsController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()
    initialize_view
  end

  def update()

    progress_update.validate_has_procured_goods = true

    progress_update.has_procured_goods =
    params[:progress_update].nil? ? nil : 
      params[:progress_update][:has_procured_goods]

    if  progress_update.valid?
      save_json
      if progress_update.has_procured_goods == "true"
        redirect_to(
          funding_application_progress_and_spend_progress_update_procurement_procurement_report_path(
            progress_update_id:  \
              @funding_application.arrears_journey_tracker.progress_update.id
          )
        )
      elsif  progress_update.has_procured_goods == "false" && has_additional_grant_conditions?
        redirect_to(
          funding_application_progress_and_spend_progress_update_additional_grant_conditions_path(
              progress_update_id:
                @funding_application.arrears_journey_tracker.progress_update.id
          )
        )

      else
        # No additional grant conditions - go to question about completion date
        redirect_to(
          funding_application_progress_and_spend_progress_update_completion_date_path(
              progress_update_id:
                @funding_application.arrears_journey_tracker.progress_update.id
          )
        )

      end

    else
      render :show
    end

  end
end

private

def progress_update
  @funding_application.arrears_journey_tracker.progress_update
end

def initialize_view()
  if  progress_update.answers_json['procurements']['has_procured_goods'] == true.to_s
    progress_update.has_procured_goods = true.to_s
  elsif  progress_update.answers_json['procurements']['has_procured_goods'] == false.to_s
    progress_update.has_procured_goods = false.to_s
  end
end

def save_json()
  answers_json = progress_update.answers_json
  answers_json['procurements']['has_procured_goods'] = progress_update.has_procured_goods

  progress_update.answers_json = answers_json
  progress_update.save
end 

def has_additional_grant_conditions?
  salesforce_additional_grant_conditions(@funding_application).any?
end
