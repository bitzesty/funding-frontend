# Controller for a page that asks about the main purpose or activities of an organisation.
class FundingApplication::GpOpenMedium::Org::MainPurposeAndActivitiesController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def show
    @organisation = current_user.organisations.first
  end

  # This method updates the main_purpose_and_activities attribute of an
  # organisation, redirecting to
  # :funding_application_gp_open_medium_board_members_or_trustees if
  # successful and re-rendering :show method if unsuccessful
  def update

    @organisation = current_user.organisations.first

    logger.info(
      'Updating main_purpose_and_activities for ' \
      "organisation ID: #{@organisation.id}"
    )

    @organisation.validate_main_purpose_and_activities = true

    @organisation.update(organisation_params)

    if @organisation.valid?

      logger.info(
        'Finished updating main_purpose_and_activities ' \
        "for organisation ID: #{@organisation.id}"
      )

      redirect_to :funding_application_gp_open_medium_board_members_or_trustees

    else

      logger.info(
        'Validation failed when attempting to update ' \
        "main_purpose_and_activities for organisation ID: #{@organisation.id}"
      )

      log_errors(@organisation)

      render :show

    end

  end

  private

  def organisation_params

    params.fetch(:organisation, {}).permit(:main_purpose_and_activities)

  end

end
