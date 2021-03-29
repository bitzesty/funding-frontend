# Controller for a page that asks for the start and
# end dates for the open medium project
class FundingApplication::GpOpenMedium::DatesController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def update

    logger.info "Updating start_date and end_date for gp_open_medium ID: " \
                "#{@funding_application.open_medium.id}"

    @funding_application.open_medium.validate_start_and_end_dates = true

    @funding_application.open_medium.update(open_medium_params)

    if @funding_application.open_medium.valid?

      start_date = Date.new(
        params[:open_medium][:start_date_year].to_i,
        params[:open_medium][:start_date_month].to_i,
        params[:open_medium][:start_date_day].to_i
      )

      end_date = Date.new(
        params[:open_medium][:end_date_year].to_i,
        params[:open_medium][:end_date_month].to_i,
        params[:open_medium][:end_date_day].to_i
      )

      @funding_application.open_medium.start_date = start_date
      @funding_application.open_medium.end_date = end_date


      @funding_application.open_medium.save

      logger.info "Successfully update start_date and end_date for open medium " \
                  "ID: #{@funding_application.open_medium.id}"

      redirect_to :funding_application_gp_project_location

    else

      logger.info "Validation failed when attempting to update start_date " \
                  "and end_date for gp_open_medium ID: #{@funding_application.open_medium.id}"

      log_errors(@funding_application.open_medium)

      store_values_in_flash

      render :show

    end

  end

  private

  def open_medium_params
    params.require(:open_medium).permit(
      :start_date_day,
      :start_date_month,
      :start_date_year,
      :end_date_day,
      :end_date_month,
      :end_date_year
    )
  end

  # Temporarily stores values in FlashHash to redisplay if there
  # have been any errors - this is necessary as we don't have
  # model attributes that are persistent for the individual date
  # items.
  def store_values_in_flash

    params[:open_medium].each do | key, value |
      flash[key] = value.empty? ? "" : value
    end

  end

end
