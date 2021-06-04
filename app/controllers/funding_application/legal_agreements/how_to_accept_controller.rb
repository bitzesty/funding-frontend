class FundingApplication::LegalAgreements::HowToAcceptController < ApplicationController
  include FundingApplicationContext
  include FundingApplicationHelper
  include ObjectErrorsLogger
  include HowToAcceptHelper

  # Method used to render the 'show' view with dynamic content
  # specific to the relevant FundingApplication
  def show

    get_and_set_instance_variables(@funding_application)

    render :show

  end

  def update

    logger.info(
      'Creating a new Agreement for funding_application ID: ' \
      "#{@funding_application.id}"
    )

    Agreement.create(funding_application_id: @funding_application.id)

    logger.info(
      'Created a new Agreement with ID: ' \
      "#{@funding_application.agreement.id}, redirecting to " \
      ':funding_application_check_project_details'
    )

    redirect_to :funding_application_check_project_details
  
  end

  private

  # Method used to retrieve and set instance variables which are then
  # referred to when rendering the corresponding view
  #
  # @param funding_application [FundingApplication] An instance of
  #                                                 FundingApplication
  def get_and_set_instance_variables(funding_application)

    @standard_terms_link = get_standard_terms_link(funding_application)

    @retrieving_a_grant_guidance_link =
      get_receiving_a_grant_guidance_link(funding_application)

    @investment_manager_name = project_owner_name(funding_application)

  end

end
