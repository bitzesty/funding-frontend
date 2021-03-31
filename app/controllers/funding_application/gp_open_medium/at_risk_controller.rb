# Controller for a page that asks whether heritage is at risk
class FundingApplication::GpOpenMedium::AtRiskController < ApplicationController
    include FundingApplicationContext
    include ObjectErrorsLogger
  
    # This method updates the heritage_at_risk and heritage_at_risk_description
    # attributes of an open_medium, redirecting to
    # :TODO if
    # successful and re-rendering :show method if unsuccessful
    def update
  
      logger.info(
        'Updating heritage_at_risk for funding_application ' \
        "ID: #{@funding_application.open_medium.id}"
      )
  
      @funding_application.open_medium.validate_heritage_at_risk = true
  
      clear_or_validate_heritage_at_risk_description(
        @funding_application,
        params
      )
        
      @funding_application.open_medium.update(open_medium_params)
  
      if @funding_application.open_medium.valid?
  
        logger.info(
          'Finished updating heritage_at_risk for funding_application ' \
          "ID: #{@funding_application.open_medium.id}"
        )
  
        redirect_to :funding_application_gp_open_medium_any_formal_designation
  
      else
  
        logger.info(
          'Validation failed when attempting to update heritage_at_risk ' \
          "for funding_application ID: #{@funding_application.open_medium.id}"
        )
  
        log_errors(@funding_application.open_medium)
  
        render :show
  
      end
  
    end
  
    private
  
    def open_medium_params
  
      params.fetch(:open_medium, {}).permit(
        :heritage_at_risk,
        :heritage_at_risk_description
      )
  
    end
  
    # If the heritage is not at risk, then we
    # should clear any existing description, otherwise we
    # should validate the incoming description
    #
    # @param [FundingApplication] funding_application An instance of an FundingApplication
    # @param [Params] params The incoming form parameters
    def clear_or_validate_heritage_at_risk_description(funding_application, params)
  
      params[:open_medium][:heritage_at_risk_description] = nil if
        params[:open_medium][:heritage_at_risk] == 'false'
  
      funding_application.open_medium.validate_heritage_at_risk_description = true if
        params[:open_medium][:heritage_at_risk] == 'true'
  
    end
  
  end
  