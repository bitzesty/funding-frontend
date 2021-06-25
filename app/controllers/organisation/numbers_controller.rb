# Controller for a page that asks for company or charity numbers.
class Organisation::NumbersController < ApplicationController
  include OrganisationContext
  include ObjectErrorsLogger

  # This method updates the company_number and/or charity_number attributes
  # of an organisation redirecting to :organisation_about if successful and
  # re-rendering the :show method if unsuccessful
  def update

    logger.info "Updating company_number/charity_number for organisation ID: #{@organisation.id}"

    @organisation.validate_company_number = true
    @organisation.validate_charity_number = true

    @organisation.update(organisation_params)

    if @organisation.valid?

      logger.info "Finished updating company_number/charity_number for organisation ID: #{@organisation.id}"

      redirect_to postcode_path 'organisation', @organisation.id

    else

      logger.info 'Validation failed when attempting to update company_number/charity_number ' \
                    "for organisation ID: #{@organisation.id}"

      log_errors(@organisation)

      render :show

    end

  end

  private

  def organisation_params
    params.require(:organisation).permit(:company_number, :charity_number)
  end

end
