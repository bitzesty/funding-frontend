class SalesforceExperienceApplication::NonCashContributionsCorrectController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show

    @non_cash_contributions = 
      get_contributions(@salesforce_experience_application, false)
    
  end


  def update

    @salesforce_experience_application.validate_non_cash_contributions_are_correct = true

    @salesforce_experience_application.non_cash_contributions_correct =
      params[:contributions_are_correct]

     if @salesforce_experience_application.valid?

      json_answers = @salesforce_experience_application.pts_answers_json

      json_answers[:non_cash_contributions_correct] =
        @salesforce_experience_application.non_cash_contributions_correct

      @salesforce_experience_application.pts_answers_json = json_answers
      @salesforce_experience_application.save

      redirect_to(
        sfx_pts_payment_timetable_work_programme_path \
          (@salesforce_experience_application.salesforce_case_id)
      )

     else

      @non_cash_contributions =
        get_contributions(@salesforce_experience_application, false)

      render :show

     end

  end
  
end
