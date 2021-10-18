class SalesforceExperienceApplication::NonCashContributionsCorrectController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show

    @non_cash_contributions = 
      get_contributions(@salesforce_experience_application, false)
      initialize_view()
  end


  def update

    @salesforce_experience_application.validate_non_cash_contributions_correct = true

    @salesforce_experience_application.non_cash_contributions_correct =
      params[:sfx_pts_payment].nil? ? nil : 
        params[:sfx_pts_payment][:non_cash_contributions_correct]

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

  private

  def initialize_view() 
    if @salesforce_experience_application
      .pts_answers_json["non_cash_contributions_correct"] == true.to_s
      @salesforce_experience_application.non_cash_contributions_correct = true.to_s
    elsif @salesforce_experience_application
      .pts_answers_json["non_cash_contributions_correct"] == false.to_s
      @salesforce_experience_application.non_cash_contributions_correct = false.to_s
    end
  end
  
end
