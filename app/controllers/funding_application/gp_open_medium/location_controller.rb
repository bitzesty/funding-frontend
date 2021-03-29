# Controller for the 'same location' page of the open medium
# funding application journey
class FundingApplication::GpOpenMedium::LocationController < ApplicationController
  include FundingApplicationContext

  def update

    @funding_application.open_medium.validate_same_location = true

    @funding_application.open_medium.update(open_medium_params)

    if @funding_application.open_medium.valid?

      if @funding_application.open_medium.same_location == 'yes'

        logger.debug(
          'Same location as organisation selected for open_medium ID: ' \
          "#{@funding_application.open_medium.id}"
        )

        set_open_medium_address_fields(
          @funding_application.open_medium,
          current_user.organisations.first
        )

        @funding_application.open_medium.save

        logger.debug(
          'Finished updating location for open_medium ID: ' \
          "#{@funding_application.open_medium.id}"
        )

        redirect_to :funding_application_gp_open_medium_description

      else

        logger.debug(
          'Different location to organisation selected for open_medium ID: ' \
          "#{@funding_application.open_medium.id}"
        )

        redirect_to postcode_path 'gp-open-medium', @funding_application.open_medium.id

      end

    else

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(
      :same_location,
      :line1,
      :line2,
      :line3,
      :townCity,
      :county,
      :postcode
    )

  end

  # Replicates address data from the organisation model linked to the current user
  # into the project model address fields
  def set_open_medium_address_fields(open_medium, organisation)

    logger.debug(
      "Setting address fields for open_medium ID: #{open_medium.id}"
    )

    open_medium.line1 = organisation.line1
    open_medium.line2 = organisation.line2
    open_medium.line3 = organisation.line3
    open_medium.townCity = organisation.townCity
    open_medium.county = organisation.county
    open_medium.postcode = organisation.postcode

    logger.debug(
      "Finished setting address fields for open_medium ID: #{open_medium.id}"
    )

  end

end
