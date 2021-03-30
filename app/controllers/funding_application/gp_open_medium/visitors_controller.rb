# Controller for a page that asks whether the heritage attracts visitors
class FundingApplication::GpOpenMedium::VisitorsController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method updates the heritage_attracts_visitors attributes of an
  # open_medium, redirecting to
  # funding_application_gp_open_medium_how_does_your_project_matter if
  # successful and re-rendering :show method if unsuccessful
  def update

    logger.info(
      'Updating heritage_attracts_visitors for funding_application ' \
      "ID: #{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_heritage_attracts_visitors = true

    clear_or_validate_visitor_numbers(
      @funding_application,
      params
    )
      
    @funding_application.open_medium.update(open_medium_params)

    if @funding_application.open_medium.valid?

      logger.info(
        'Finished updating heritage_attracts_visitors for ' \
        "funding_application ID: #{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_how_does_your_project_matter

    else

      logger.info(
        'Validation failed when attempting to update heritage_attracts_visitors ' \
        "for funding_application ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.fetch(:open_medium, {}).permit(
      :heritage_attracts_visitors,
      :visitors_in_last_financial_year,
      :visitors_expected_per_year
    )

  end

  # If the heritage_attracts_visitors is false, then we
  # should clear any existing visitor numbers, otherwise we
  # should validate the incoming visitor numbers
  #
  # @param [FundingApplication] funding_application An instance of FundingApplication
  # @param [Params] params The incoming form parameters
  def clear_or_validate_visitor_numbers(funding_application, params)

    if params[:open_medium][:heritage_attracts_visitors] == 'false'

      params[:open_medium][:visitors_in_last_financial_year] = nil
      params[:open_medium][:visitors_expected_per_year] = nil

    end

    if params[:open_medium][:heritage_attracts_visitors] == 'true'

      funding_application.open_medium.validate_visitors_in_last_financial_year = true
      funding_application.open_medium.validate_visitors_expected_per_year = true

    end

  end

end
