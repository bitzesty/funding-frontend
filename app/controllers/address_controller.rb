# Controller class for address-related functionality. Provides the ability
# to update address details for User, Project and Organisation model
# objects.
class AddressController < ApplicationController
  include ObjectErrorsLogger
  include PostcodeLookup
  include ImportHelper
  include UserHelper
  before_action :authenticate_user!, :check_and_set_model_type

  def assign_address_attributes

    assign_attributes(@model_object)

    render :show

  end

  # This method updates the address for a given model object, which could
  # be of types user, organisation or project. If of type user, then the
  # address attributes are replicated to a separate address record which is
  # then associated with the user and it's associated person record
  def update

    logger.info "Updating address for #{@type} ID: #{@model_object.id}"

    @model_object.validate_address = true

    @model_object.update(model_params)

    if @model_object.valid?

      logger.info "Finished updating address for #{@type} ID: " \
                  "#{@model_object.id}"

      if @type == 'organisation'

        if Flipper.enabled?(:import_existing_account_enabled) &&
          retrieve_matching_sf_orgs(@model_object).size == 0

          redirect_to organisation_existing_organisations_path(params['id'])

        else
          redirect_to organisation_mission_path(params['id'])
        end

      elsif @type == 'preapplication'

        if Flipper.enabled?(:import_existing_account_enabled) &&
          retrieve_matching_sf_orgs(@model_object).size > 0

          redirect_to organisation_existing_organisations_path(@model_object.id)

        else
          redirect_to(
            pre_application_organisation_mission_path(
              pre_application_id: params['id'],
              organisation_id: @model_object.id
            )
          )
        end

      elsif @type == 'project'

        redirect_to funding_application_gp_project_description_path(@model_object.funding_application.id)

      elsif @type == 'gp-open-medium'

        redirect_to funding_application_gp_open_medium_description_path(@model_object.funding_application.id)

      elsif @type == 'user'

        # Caters to a situation where original applicants have no person assigned to the user.
        check_and_set_person_address(@model_object) if @model_object.person.present?

        redirect_to :authenticated_root

      end

    else

      logger.info 'Validation failed when attempting to update address for ' \
                  "#{@type} ID: #{@model_object.id}"

      log_errors(@model_object)

      render :show

    end


  end 

  private

  # Checks for a known type of model in the params.
  # If correct, then assign the model type to a @type instance variable.
  def check_and_set_model_type
    if %w[user organisation project gp-open-medium preapplication].include? params[:type]
      @type = params[:type]
      case @type
      when 'organisation'
        @model_object = Organisation.find(params[:id])
        redirect_to :root unless current_user.organisations.first&.id == @model_object&.id
      when 'project'
        @model_object = Project.find(params[:id])
        redirect_to :root unless current_user.id == @model_object&.user_id
      when 'gp-open-medium'
        @model_object = OpenMedium.find(params[:id])
        redirect_to :root unless current_user.id == @model_object&.user_id
      when 'user'
        users_organisation = UsersOrganisation.find_by(organisation_id: params[:id])
        @model_object = current_user
        redirect_to :root unless users_organisation.user_id == current_user.id
      when 'preapplication'
        # When @type is 'preapplication', we need to actually set the
        # address against the associated Organisation object
        pre_application = PreApplication.find(params[:id])
        @model_object = Organisation.find(pre_application.organisation_id)
        redirect_to :root unless current_user.organisations.first&.id == @model_object&.id
      end
    else
      redirect_to :root
    end
  end

  def model_params

    # Ensure that the required param is set to either the @type value,
    # or 'organisation' if @type is equal to 'preapplication'. We do
    # this to ensure that during a pre-application journey, we don't
    # require a param of 'preapplication', when we are actually dealing
    # with an organisation object
    if @type == 'preapplication'
      model_type = 'organisation'
    elsif @type == 'gp-open-medium'
      model_type = 'open_medium'
    else
      model_type = @type
    end
    # model_type = @type == 'preapplication' ? 'organisation' : @type

    params.require(model_type)
          .permit(:name, :line1, :line2, :line3,
                  :townCity, :county, :postcode)
  end

end
