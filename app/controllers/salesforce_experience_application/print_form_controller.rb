class SalesforceExperienceApplication::PrintFormController < ApplicationController
  before_action :authenticate_user!
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show
    retrieve_form_data()
  end

  def update
    redirect_to(
      sfx_pts_payment_upload_permission_to_start_path \
        (@salesforce_experience_application.salesforce_case_id)
    )
  end

  private

  def retrieve_form_data()
    @pts_answers = @salesforce_experience_application.pts_answers_json
    @project_info = get_info_for_start_page(
      @salesforce_experience_application.salesforce_case_id)
    @approved_purposes = get_approved_purposes(
      @salesforce_experience_application.salesforce_case_id)
    @agreed_costs =  get_agreed_costs(@salesforce_experience_application)
    @total_contingency = get_total_contingency(@agreed_costs)
    @attached_agreed_docs = @salesforce_experience_application.agreed_costs_files.blobs
    @cash_contributions =  get_contributions(@salesforce_experience_application, true)
    @cash_contributions_evidence =  @salesforce_experience_application.cash_contributions_evidence_files.blobs
    @fundraising_evidence_files = @salesforce_experience_application.fundraising_evidence_files.blobs
    @non_cash_contributions = get_contributions(@salesforce_experience_application, false)
    @timetable_work_programme_files = @salesforce_experience_application.timetable_work_programme_files.blobs
    @project_management_structure_files = @salesforce_experience_application.project_management_structure_files.blobs
    @property_ownership_evidence_files = @salesforce_experience_application.property_ownership_evidence_files.blobs
    @statutory_permission_or_licence = @salesforce_experience_application.statutory_permission_or_licence
    @total_vat_cost = get_vat_costs(@salesforce_experience_application)
    @payment_percentage = get_payment_percentage(@salesforce_experience_application)
    @user = current_user
  end

end