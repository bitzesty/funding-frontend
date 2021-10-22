class SalesforceExperienceApplication::StatutoryPermissionOrLicence::SummaryController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show
    @total_count = 
      @salesforce_experience_application.statutory_permission_or_licence.count
  end

  def update
    
    @salesforce_experience_application.\
      validate_add_another_statutory_permission_or_licence = true
    
    @salesforce_experience_application.\
      add_another_statutory_permission_or_licence = 
        params[:sfx_pts_payment].nil? ? nil : \
          params[:sfx_pts_payment]\
            [:add_another_statutory_permission_or_licence]

    if @salesforce_experience_application.valid?

      if @salesforce_experience_application.\
        add_another_statutory_permission_or_licence == true.to_s

        redirect_to(
          sfx_pts_payment_statutory_permission_or_licence_add_path \
            (@salesforce_experience_application.salesforce_case_id)
        )

      else
        
        redirect_to(
          sfx_pts_payment_signatories_path \
            (@salesforce_experience_application.salesforce_case_id)
        )

      end


    else

      render :show

    end

  end

  def delete 

    StatutoryPermissionOrLicence.destroy(params[:statutory_permission_or_licence_id])

    logger.info(
      'Applicant has destroyed cash statutory_permission_or_licence_id: ' \
        "#{params[:statutory_permission_or_licence_id]} " \
          "from sfx_pts_payment_id: #{@salesforce_experience_application.id}"
    )

    redirect_to(
      sfx_pts_payment_statutory_permission_or_licence_summary_path(
        @salesforce_experience_application.salesforce_case_id)
    )

  end
  
end
