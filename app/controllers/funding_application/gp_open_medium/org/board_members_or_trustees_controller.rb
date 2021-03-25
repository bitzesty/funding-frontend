# Controller for a page that asks about the number of board
# members or trustees of an organisation.
class FundingApplication::GpOpenMedium::Org::BoardMembersOrTrusteesController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def show
    @organisation = current_user.organisations.first
  end

  # This method updates the board_members_or_trustees attribute of an
  # organisation, redirecting to :TODO if successful
  # and re-rendering :show method if unsuccessful
  def update

    @organisation = current_user.organisations.first

    logger.info(
      'Updating board_members_or_trustees for ' \
      "organisation ID: #{@organisation.id}"
    )

    @organisation.validate_board_members_or_trustees = true

    @organisation.update(organisation_params)

    if @organisation.valid?

      logger.info(
        'Finished updating board_members_or_trustees ' \
        "for organisation ID: #{@organisation.id}"
      )

      render :show

      # redirect_to :pre_application_project_enquiry_previous_contact if @pre_application.pa_project_enquiry.present?

    else

      logger.info(
        'Validation failed when attempting to update ' \
        "board_members_or_trustees for organisation ID: #{@organisation.id}"
      )

      log_errors(@organisation)

      render :show

    end

  end

  private

  def organisation_params

    params.fetch(:organisation, {}).permit(:board_members_or_trustees)

  end

end
