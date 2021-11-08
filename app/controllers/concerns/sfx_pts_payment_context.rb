# Controller concern used to set the @salesforce_experience_application
# instance variable
module SfxPtsPaymentContext
	extend ActiveSupport::Concern
	included do
		before_action :authenticate_user!, :set_salesforce_experience_application
	end

  # This method retrieves a SfxPtsPayment instance based on the id
  # found in the URL parameters and the current authenticated
  # user's id, setting it as an instance variable for use in
  # related controllers.
  #
  # If no SfxPtsPayment instance matching the parameters is found,
  # or the SfxPtsPayment instance is not suitable for the route being used,
  # then the user is redirected to the applications dashboard.
	def set_salesforce_experience_application

    @salesforce_experience_application = SfxPtsPayment.find_by(
      salesforce_case_id: params[:salesforce_case_id]
    )

    if @salesforce_experience_application.blank? || unsuitable?(
        @salesforce_experience_application, 
        request.path
      )

        logger.error("User redirected to root, error in " \
          "salesforce_experience_application_context.rb")

        redirect_to :authenticated_root

    end

  end

  # returns true if the SfxPtsPayment has been submitted.  Unless
  # the route being called is permitted for that - like /confirmation
  #
  # @param [SfxPtsPayment] salesforce_experience_application Instance of 
  #                                                        SfxPtsPayment
  # @param [String] path Request passed from outer scope
  # @return [Boolean] True if unsuitable
  #
  def unsuitable?(salesforce_experience_application, path)
  
    salesforce_experience_application.submitted_on.present? && \
      path.exclude?('/confirmation')

  end

end
