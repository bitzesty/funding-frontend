# Controller for a page that asks about the social media activities of an organisation.
class FundingApplication::GpOpenMedium::Org::SocialMediaController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def show
    @organisation = current_user.organisations.first
  end

  # This method updates the social_media_info attribute of an
  # organisation, redirecting to
  # :funding_application_gp_open_medium_board_members_or_trustees if
  # successful and re-rendering :show method if unsuccessful
  def update

    @organisation = current_user.organisations.first

    logger.info(
      'Updating social_media_info for ' \
      "organisation ID: #{@organisation.id}"
    )

    @organisation.validate_social_media_info = true

    @organisation.update(organisation_params)

    if @organisation.valid?

      logger.info(
        'Finished updating social_media_info ' \
        "for organisation ID: #{@organisation.id}"
      )

      # redirect_to :funding_application_gp_open_medium_board_members_or_trustees
      render :show

    else

      logger.info(
        'Validation failed when attempting to update ' \
        "social_media_info for organisation ID: #{@organisation.id}"
      )

      log_errors(@organisation)

      render :show

    end

  end

  private

  def organisation_params

    params.fetch(:organisation, {}).permit(:social_media_info)

  end

end
  