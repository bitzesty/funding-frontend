# Controller for a view which asks about capital works ownership
class FundingApplication::GpOpenMedium::OwnershipController < ApplicationController
    include FundingApplicationContext
    include ObjectErrorsLogger
  
    # This method updates the ownership_type and accompanying description
    # attributes of an open_medium redirecting to
    # :funding_application_gp_open_medium_acquisition if successful and
    # re-rendering :show method if unsuccessful
    def update
  
      logger.info(
        'Updating ownership_type for open medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )
  
      @funding_application.open_medium.validate_ownership_type = true

      clear_or_validate_ownership_type_descriptions(
        @funding_application,
        params
      )
  
      if @funding_application.open_medium.update(open_medium_params)
  
        logger.debug(
          'Finished updating ownership_type for open_medium ' \
          "ID: #{@funding_application.open_medium.id}"
        )
  
        # TODO: Replace with :funding_application_gp_open_medium_acquisition
        #       when the corresponding branch has been merged
        redirect_to :funding_application_gp_open_medium_do_you_need_permission
  
      else
  
        logger.info(
          'Validation failed when attempting to update ownership_type ' \
          "for open_medium ID: #{@funding_application.open_medium.id}"
        )
  
        log_errors(@funding_application.open_medium)
  
        render :show
  
      end
  
    end
  
    private
  
    def open_medium_params
  
      params.fetch(:open_medium, {}).permit(
        :ownership_type,
        :ownership_type_org_description,
        :ownership_type_pp_description,
        :ownership_type_neither_description,
        :ownership_file
      )
  
    end

    # Clear or validate ownership type descriptions based on ownerhip_type param
    #
    # @param [FundingApplication] funding_application An instance of an FundingApplication
    # @param [Params] params The incoming form parameters
    def clear_or_validate_ownership_type_descriptions(funding_application, params)
  
      if params[:open_medium][:ownership_type] == 'organisation'

        funding_application.open_medium.validate_ownership_type_org_description = true

        params[:open_medium][:ownership_type_pp_description] = nil
        params[:open_medium][:ownership_type_neither_description] = nil

      end

      if params[:open_medium][:ownership_type] == 'project_partner'

        funding_application.open_medium.validate_ownership_type_pp_description = true

        params[:open_medium][:ownership_type_org_description] = nil
        params[:open_medium][:ownership_type_neither_description] = nil
        params[:open_medium][:ownership_file] = nil

      end

      if params[:open_medium][:ownership_type] == 'neither'

        funding_application.open_medium.validate_ownership_type_neither_description = true

        params[:open_medium][:ownership_type_org_description] = nil
        params[:open_medium][:ownership_type_pp_description] = nil
        params[:open_medium][:ownership_file] = nil

      end
  
    end
  
  end
  