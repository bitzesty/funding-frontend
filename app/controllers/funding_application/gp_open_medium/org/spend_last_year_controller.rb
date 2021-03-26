# Controller for a page that asks about what an organisation has spent over
# the last financial year.
class FundingApplication::GpOpenMedium::Org::SpendLastYearController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def show
    @organisation = current_user.organisations.first
  end

  # This method updates the spend_in_last_financial_year attribute of an
  # organisation, redirecting to
  # :todo if
  # successful and re-rendering :show method if unsuccessful
  def update

    @organisation = current_user.organisations.first

    logger.info(
      'Updating spend_in_last_financial_year for ' \
      "organisation ID: #{@organisation.id}"
    )

    # Strip commas from the unrestricted_funds input
    params[:organisation][:spend_in_last_financial_year] = 
      params[:organisation][:spend_in_last_financial_year].gsub(/[\s,]/ , '')

    @organisation.validate_spend_in_last_financial_year = true

    @organisation.update(organisation_params)

    if @organisation.valid?

      logger.info(
        'Finished updating spend_in_last_financial_year ' \
        "for organisation ID: #{@organisation.id}"
      )

      redirect_to :funding_application_gp_open_medium_unrestricted_funds

    else

      logger.info(
        'Validation failed when attempting to update ' \
        "spend_in_last_financial_year for organisation ID: #{@organisation.id}"
      )

      log_errors(@organisation)

      render :show

    end

  end

  private

  def organisation_params

    params.fetch(:organisation, {}).permit(:spend_in_last_financial_year)

  end

end
