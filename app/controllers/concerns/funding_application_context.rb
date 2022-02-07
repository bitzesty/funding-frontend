# Controller concern used to set the @funding_application
# instance variable
module FundingApplicationContext
  extend ActiveSupport::Concern
  included do
    before_action :authenticate_user!, :set_funding_application
  end

  # This method retrieves a FundingApplication object based on the id
  # found in the URL parameters and the current authenticated
  # user's id, setting it as an instance variable for use in
  # funding application-related controllers.
  #
  # If no FundingApplication object matching the parameters is found,
  # then the user is redirected to the applications dashboard.
  def set_funding_application

    @funding_application = FundingApplication.find_by(
      id: params[:application_id],
      organisation_id: current_user.organisations.first&.id
    )
    
    # Consider adding set_award_type(@funding_application) here 
    # rather than calling throughout the app when needed.  Would
    # Need testing on all journeys.

    if no_valid_funding_application_found? ||
      invalid_view_for_submitted_application? ||
        invalid_view_for_submitted_agreement?

          logger.error(
            "User redirected to root, error in funding_application_context.rb. " \
              "no_valid_funding_application_found?: " \
                "#{no_valid_funding_application_found?} " \
                  "invalid_view_for_submitted_application?: " \
                    "#{invalid_view_for_submitted_application?} " \
                      "invalid_view_for_submitted_agreement?: " \
                        "#{invalid_view_for_submitted_agreement?}" \
          )

          redirect_to :authenticated_root

    end

  end

  # Returns true if trying to use an unsuitable view for an application
  # where the agreement journey has concluded with a submission.
  def invalid_view_for_submitted_agreement?
    @funding_application&.agreement_submitted_on.present? && \
      not_an_allowed_paths_for_submitted_agreements(request.path)
  end

  # Returns true if trying to use an unsuitable view for a submitted applctn
  def invalid_view_for_submitted_application?
    @funding_application&.submitted_on.present? && \
      not_an_allowed_paths_for_submitted_projects(request.path)
  end

  # Returns true if no suitable funding_application found
  def no_valid_funding_application_found?
    !@funding_application.present? || \
      (@funding_application.project.nil? && \
        @funding_application.open_medium.nil?)
  end
  
  # Returns true if the passed path is NOT allowed for submitted applications.
  def not_an_allowed_paths_for_submitted_projects(path)
    path.exclude?('/application-submitted') && \
      path.exclude?('/tasks') && \
        path.exclude?('/payments') && \
          path.exclude?('/agreement') && \
            path.exclude?('/summary') 
  end

  # Returns true if the passed path is NOT allowed for submitted agreements.
  def not_an_allowed_paths_for_submitted_agreements(path)
    path.exclude?('/agreement/submitted') && \
      path.exclude?('awaiting-signatories') && \
        path.exclude?('/tasks') && \
          path.exclude?('/payments') && \
            path.exclude?('/view-signed') 
  end

end
