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

    if !@funding_application.present? || (@funding_application.project.nil? && @funding_application.open_medium.nil?) ||
      (@funding_application.submitted_on.present? && !request.path.include?('/application-submitted') && !request.path.include?('/payment-request/'))

        logger.error("User redirected to root, error in funding_application_context.rb")

        redirect_to :authenticated_root

    end

  end

end
