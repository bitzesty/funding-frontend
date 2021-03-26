# Controller for a page that asks about the level of
# unrestricted funds of an organisation.
class FundingApplication::GpOpenMedium::Org::UnrestrictedFundsController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def show
    @organisation = current_user.organisations.first
  end

  # This method updates the unrestricted_funds attribute of an
  # organisation, redirecting to :TODO if successful
  # and re-rendering :show method if unsuccessful
  def update

    @organisation = current_user.organisations.first

    logger.info(
      'Updating unrestricted_funds for ' \
      "organisation ID: #{@organisation.id}"
    )

    # Strip commas from the unrestricted_funds input
    params[:organisation][:unrestricted_funds] = 
      params[:organisation][:unrestricted_funds].gsub(/[\s,]/ , '')

    @organisation.validate_unrestricted_funds = true

    @organisation.update(organisation_params)

    if @organisation.valid?

      logger.info(
        'Finished updating unrestricted_funds ' \
        "for organisation ID: #{@organisation.id}"
      )

      redirect_to :funding_application_gp_open_medium_unrestricted_funds

    else

      logger.info(
        'Validation failed when attempting to update ' \
        "unrestricted_funds for organisation ID: #{@organisation.id}"
      )

      log_errors(@organisation)

      render :show

    end

  end

  private

  def organisation_params

    params.fetch(:organisation, {}).permit(:unrestricted_funds)

  end

end
