# Stub controller
class FundingApplication::GpOpenMedium::VolunteersController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method adds a volunteer to a funding_application, redirecting back to
  # :funding_application_gp_open_medium_volunteers if successful and
  # re-rendering :show method if unsuccessful
  def update

    # Empty flash values to ensure that we don't redisplay them unnecessarily
    flash[:description] = ''
    flash[:hours] = ''

    logger.info(
      'Adding volunteer for funding_application ID: ' \
      "#{@funding_application.id}"
    )

    # @funding_application.validate_volunteers = true

    if @funding_application.update(funding_application_params)

      logger.info(
        'Successfully added volunteer for funding_application ID: ' \
        "#{@funding_application.id}"
      )

      redirect_to :funding_application_gp_open_medium_volunteers

    else

      logger.info(
        'Validation failed when adding volunteer for funding_application ' \
        "ID: #{@funding_application.id}"
      )

      log_errors(@funding_application)

      # Store flash values to display them again when re-rendering the page
      flash[:description] =
        params['funding_application']['volunteers_attributes']['0']['description']
      flash[:hours] =
        params['funding_application']['volunteers_attributes']['0']['hours']

      render :show

    end

  end

  # This method deletes a volunteer and the associated link table record
  # redirecting back to :funding_application_open_medium_volunteers once
  # completed
  def delete

    logger.info(
      'User has selected to delete volunteer ID: ' \
      "#{params[:volunteer_id]} from funding_application ID: " \
      "#{@funding_application.id}"
    )

    volunteer = @funding_application.volunteers.find(
      params[:volunteer_id]
    )

    link_record = FundingApplicationsVlntr.find_by(volunteer_id: params[:volunteer_id])

    logger.info("Deleting funding_applications_vlntrs ID: #{ link_record.id }")

    link_record.destroy

    logger.info(
      'Finished deleting funding_applications_vlntrs ID: ' \
      "#{ link_record.id }"
    )

    logger.info("Deleting volunteer ID: #{volunteer.id}")

    volunteer.destroy

    logger.info("Finished deleting volunteer ID: #{volunteer.id}")

    redirect_to :funding_application_gp_open_medium_volunteers

  end

  private

  def funding_application_params

    params.fetch(:funding_application, {}).permit(
      volunteers_attributes: [:description, :hours]
    )

  end

end
