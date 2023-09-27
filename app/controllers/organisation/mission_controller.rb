# Controller for a page that asks about the mission, or objectives, of an organisation.
class Organisation::MissionController < ApplicationController
  include OrganisationContext
  include ObjectErrorsLogger

  # This method updates the mission attribute of an organisation,
  # redirecting to :organisation_signatories if successful and re-rendering
  # :show method if unsuccessful
  def update

    logger.info "Updating mission for organisation ID: #{@organisation.id}"

    ensure_mission_params

    @organisation.validate_mission = true

    @organisation.update(organisation_params)

    if @organisation.valid?

      logger.info "Finished updating mission for organisation ID: #{@organisation.id}"

      redirect_to :organisation_summary

    else

      logger.info "Validation failed when attempting to update mission for organisation ID: #{@organisation.id}"

      log_errors(@organisation)

      render :show

    end

  end

  private

  def organisation_params

    params.fetch(:organisation, {}).permit(:mission, mission: [])

  end

    # This method ensures that if no mission is chosen by the user
    # the mission array is set back to empty.
  def ensure_mission_params

    if params[:organisation]  

         params[:organisation][:mission] ||= []

    else

        params[:organisation] = { mission: [] }
    
    end

  end

end
