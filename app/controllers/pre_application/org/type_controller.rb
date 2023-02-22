# Controller for a page that asks for details on the type of organisation applying.
class PreApplication::Org::TypeController < ApplicationController
    include OrganisationContext
    include ObjectErrorsLogger
    include PreApplicationContext

    # This method updates the org_type attribute of an organisation,
    # redirecting to :pre_application_organisation_ if successful and re-rendering
    # :show method if unsuccessful
    def update

      logger.info "Updating org_type for organisation ID: #{@organisation.id}"
  
      @organisation.validate_org_type = true
  
      if @organisation.update(organisation_params)
  
        logger.info "Finished updating org_type for organisation ID: #{@organisation.id}"

        if Flipper.enabled?(:import_existing_account_enabled)
          redirect_to(
            pre_application_organisation_mission_path(
              pre_application_id:  @pre_application.id,
              organisation_id: @organisation.id
            )
          )
        else
          redirect_to(
            postcode_path(
              'preapplication',
              @pre_application.id
            )
          )
        end
  
      else
  
        logger.info "Validation failed when attempting to update org_type for organisation ID: #{@organisation.id}"
  
        log_errors(@organisation)
  
        render :show
  
      end

    end
  
    private
  
    def organisation_params
      params.fetch(:organisation, {}).permit(:org_type)
    end

  end
  