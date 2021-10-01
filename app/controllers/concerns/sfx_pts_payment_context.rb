# Controller concern used to set the @salesforce_experience_application
# instance variable
module SfxPtsPaymentContext
	extend ActiveSupport::Concern
	included do
		before_action :authenticate_user!, :set_salesforce_experience_application
	end

	def set_salesforce_experience_application

    @salesforce_experience_application = SfxPtsPayment.find_by(
      salesforce_case_id: params[:salesforce_case_id]
    )

    unless @salesforce_experience_application.present?

        logger.error("User redirected to root, error in salesforce_experience_application_context.rb")

        redirect_to :authenticated_root

    end

  end

end



  