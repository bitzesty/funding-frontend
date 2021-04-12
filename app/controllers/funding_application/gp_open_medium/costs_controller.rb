# Stub controller
class FundingApplication::GpOpenMedium::CostsController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger
  before_action :remove_flash_values

  # This method is used to control page flow based on whether a not a
  # user has added costs to a funding_application
  def validate_and_redirect

    logger.info(
      'Confirming that user has added costs for funding_application ID: ' \
      "#{@funding_application.id}"
    )

    @funding_application.validate_has_associated_project_costs = true

    if @funding_application.valid?

      logger.info(
        "Costs found for funding_application ID: #{@funding_application.id}"
      )

      redirect_to(
        :funding_application_gp_open_medium_are_you_getting_cash_contributions
      )

    else

      logger.info(
        'No project costs found for funding_application ID: ' \
        "#{@funding_application.id}"
      )

      log_errors(@funding_application)

      render :show

    end

  end

  # This method adds a cost to a funding_application, redirecting back to
  # :funding_application_gp_open_medium_costs if successful and
  # re-rendering :show method if unsuccessful
  def update

    logger.info(
      "Adding cost for funding_application ID: #{@funding_application.id}"
    )

    # Empty flash values to ensure that we don't redisplay them unnecessarily
    remove_flash_values

    @funding_application.validate_project_costs = true

    if @funding_application.update(funding_application_params)

      logger.info(
        "Succesfully added project cost for funding_application ID: " \
        "#{@funding_application.id}"
      )

      redirect_to :funding_application_gp_open_medium_costs

    else

      logger.info(
        "Validation failed when attempting to add cost for " \
        "funding_application ID: #{@funding_application.id}"
      )

      log_errors(@funding_application)

      # Store flash values to display them again when re-rendering the page
      flash[:description] =
        params['funding_application']['project_costs_attributes']['0']['description']
      flash[:amount] =
        params['funding_application']['project_costs_attributes']['0']['amount']
      flash[:vat_amount] =
        params['funding_application']['project_costs_attributes']['0']['vat_amount']
      flash[:cost_type] =
        params['funding_application']['project_costs_attributes']['0']['cost_type']

      render :show

    end

  end

  # This method deletes a funding_application cost, redirecting back to
  # :funding_application_gp_open_medium_costs once completed.
  # If no cost is found, then an ActiveRecord::RecordNotFound exception is
  # raised
  def delete

      logger.info(
        'User has selected to delete cost ID: ' \
        "#{params[:project_cost_id]} from funding_application ID: " \
        "#{@funding_application.id}"
      )

      cost = @funding_application.project_costs.find(params[:project_cost_id])

      link_record = FundingApplicationsCost.find_by(
        project_cost_id: params[:project_cost_id]
      )

      logger.info(
        "Deleting funding_applications_costs ID: #{ link_record.id }"
      )

      link_record.destroy

      logger.info(
        'Finished deleting funding_applications_costs ID: ' \
        "#{ link_record.id }"
      )

      logger.info "Deleting cost ID: #{cost.id}"

      cost.destroy

      logger.info "Finished deleting cost ID: #{cost.id}"

      redirect_to :funding_application_gp_open_medium_costs

  end

  private

  def funding_application_params

    params.fetch(:funding_application, {}).permit(
      project_costs_attributes: [
        :description,
        :amount,
        :cost_type,
        :vat_amount
      ]
    )

  end

  def remove_flash_values
    flash[:description] = ''
    flash[:amount] = ''
    flash[:cost_type] = ''
    flash[:vat_amount] = ''
  end

end
