class AdminPortal::LandingPageController < ApplicationController
  include AdminPortalContext

  def update

    applicant_email =
      params.require('no_model').permit('email')['email'].downcase.strip

    applicant_user_id = User.find_by(email: applicant_email)&.id

    if applicant_user_id.present?

      Rails.logger.info(
        "User #{applicant_user_id} found by admin portal"
      )

      redirect_to(
        admin_portal_user_found_path(
        user_id: applicant_user_id
        )
      )

    else
      @not_found = true
      Rails.logger.info("User not found with email #{applicant_email}")
      render :show
    end

  end

end
