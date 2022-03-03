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

    if no_valid_funding_application_found? ||
      invalid_view_for_submitted_application? ||
        invalid_view_for_submitted_agreement? ||
          invalid_view_for_progress_and_spend?

          logger.error(
            "User redirected to root, error in funding_application_context.rb. " \
              "no_valid_funding_application_found?: " \
                "#{no_valid_funding_application_found?} " \
                  "invalid_view_for_submitted_application?: " \
                    "#{invalid_view_for_submitted_application?} " \
                      "invalid_view_for_submitted_agreement?: " \
                        "#{invalid_view_for_submitted_agreement?}" \
                          "invalid_view_for_progress_and_spend?: " \
                            "#{invalid_view_for_progress_and_spend?}" \
          )

          redirect_to :authenticated_root

    end

  end

  # True if the application at the submitted application stage, but we're using
  # and invalid path.
  #
  # Firstly checks if the application was submitted
  # And that an agreement journey has not concluded yet.
  #
  # Above checks qualify this as a submitted application 
  # so only allow certain paths
  def invalid_view_for_submitted_application?
    @funding_application&.submitted_on.present? && \
      @funding_application&.agreement_submitted_on.blank? && \
        not_an_allowed_paths_for_submitted_projects(request.path)
  end

  # True if the application is a submitted agreement, and we're using
  # and invalid path.
  #
  # Firstly checks if the agreement journey has concluded with a submission 
  # And that an arrears payment journey has not started yet.
  #
  # Above checks qualify this as a submitted agreement 
  # so only allow certain paths
  def invalid_view_for_submitted_agreement?
    @funding_application&.agreement_submitted_on.present? && \
      !@funding_application&.payment_can_start? && \
        not_an_allowed_paths_for_submitted_agreements(request.path)
  end

  # True if the application has arrears payment underway
  # and an invalid path is being tried
  #
  # WIP
  #
  def invalid_view_for_progress_and_spend?

    # if the last arrears payment has been submitted (stubbed as false)
    false && not_an_allowed_path_for_progress_and_spend(request.path)

  end

  # Returns true if no suitable funding_application found
  def no_valid_funding_application_found?
    !@funding_application.present? || \
      (@funding_application.project.nil? && \
        @funding_application.open_medium.nil?)
  end
  
  # Returns true if the passed path is NOT allowed for submitted applications.
  # Agreements excluded until there is a flag to confirm agreements can start
  def not_an_allowed_paths_for_submitted_projects(path)
    
    path.exclude?('/application-submitted') && \
      path.exclude?('/tasks') && \
        path.exclude?('/agreement') && \
          path.exclude?('/summary')
  end

  # Returns true if the passed path is NOT allowed for submitted agreements.
  def not_an_allowed_paths_for_submitted_agreements(path)
    path.exclude?('/agreement/submitted') && \
      path.exclude?('awaiting-signatories') && \
        path.exclude?('/tasks') && \
          path.exclude?('/view-signed') && \
            # Payments is excluded, until we add a flag to check it can start
            path.exclude?('/payments')
  end

  # Returns true if the passed path is NOT allowed for progress and spend journey.
  def not_an_allowed_path_for_progress_and_spend(path)
    path.exclude?('/agreements')
  end

end
