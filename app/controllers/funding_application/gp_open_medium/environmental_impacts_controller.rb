class FundingApplication::GpOpenMedium::EnvironmentalImpactsController < ApplicationController
    include FundingApplicationContext
    include ObjectErrorsLogger
  
    # This method updates the environmental_impacts_description attribute of
    # an OpenMedium, redirecting to
    # :funding_application_gp_open_medium_your_project_heritage if successful
    # and re-rendering :show method if unsuccessful
    def update
  
      logger.info(
        'Updating environmental_impacts_description for ' \
        "open_medium ID: #{@funding_application.open_medium.id}"
      )
  
      @funding_application.open_medium.validate_environmental_impacts_description = true
  
      @funding_application.open_medium.update(open_medium_params)
  
      if @funding_application.open_medium.valid?
  
        logger.info(
          'Finished updating environmental_impacts_description for ' \
          "open_medium ID: #{@funding_application.open_medium.id}"
        )
  
        redirect_to :funding_application_gp_open_medium_your_project_heritage
  
      else
        logger.info(
          'Validation failed when attempting to update ' \
          'environmental_impacts_description for open_medium ID: ' \
          "#{@funding_application.open_medium.id}"
        )
  
        log_errors(@funding_application.open_medium)
  
        render :show
  
      end
  
    end
  
    private
  
    def open_medium_params
      params.require(:open_medium).permit(:environmental_impacts_description)
    end
  
  end
  