# Controller for a page that asks whether project is being delivered
# in partnership
class FundingApplication::GpOpenMedium::PartnershipController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the is_partnership and partnership_details
  # attributes of an open_medium, redirecting to
  # :TODO if
  # successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating is_partnership for funding_application ' \
      "ID: #{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_is_partnership = true

    clear_or_validate_partnership_details(
      @funding_application,
      params
    )

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating is_partnership for funding_application ' \
        "ID: #{@funding_application.open_medium.id}"
      )

      redirect_to(
        :funding_application_gp_open_medium_how_will_your_project_involve_people
      )

    else

      logger.info(
        'Validation failed when attempting to update is_partnership ' \
        "for funding_application ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(
      :is_partnership,
      :partnership_details,
      :partnership_agreement_file
    )

  end

  # If not delivering in partnership, then we
  # should clear any existing description, otherwise we
  # should validate the incoming description
  #
  # @param [FundingApplication] funding_application An instance of an FundingApplication
  # @param [Params] params The incoming form parameters
  def clear_or_validate_partnership_details(funding_application, params)

    if params[:open_medium][:is_partnership] == 'false'
      params[:open_medium][:partnership_details] = nil
      params[:open_medium][:partnership_agreement_file] = nil
    end

    funding_application.open_medium.validate_partnership_details = true if
      params[:open_medium][:is_partnership] == 'true'

  end

end
