class FundingApplication::GpOpenMedium::DeclarationController < ApplicationController
  include FundingApplicationContext
  include FundingApplicationHelper
  include ObjectErrorsLogger
  include Mailers::GpProjectMailerHelper

  # This method is used to set the @standard_terms_link instance variable,
  # which is then used on the declaration partial
  def show_declaration

    set_standard_terms_link(
      @funding_application.project_costs,
      @funding_application.cash_contributions
    )

  end

  # This method updates the confirm_declaration attribute of a gp_open_medium,
  # triggering the application submission and redirecting to
  # :funding_application_gp_open_medium_application_submitted if successful and
  # re-rendering :show_confirm_declaration method if unsuccessful
  def update_confirm_declaration

    logger.info(
      'Updating confirm_declaration for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_confirm_declaration = true

    if @funding_application.open_medium.update(confirm_declaration_params)

      logger.info(
        'Finished updating confirm_declaration for open_medium ID:' \
        "#{@funding_application.open_medium.id}"
      )

      if Flipper.enabled?(:grant_programme_sff_medium)

        send_funding_application_to_salesforce(
          @funding_application,
          current_user,
          current_user.organisations.first
        )
        
        send_project_submission_confirmation(
          current_user.id,
          current_user.email,
          @funding_application.project_reference_number
        )

        redirect_to :funding_application_gp_open_medium_application_submitted

      else

        redirect_to :funding_application_gp_open_medium_confirm_declaration

      end

    else

      logger.info(
        'Validation failed when attempting to update confirm_declaration ' \
        "for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show_confirm_declaration

    end


  end

  # This method updates the declaration-related attributes of a gp_open_medium,
  # redirecting to :funding_application_gp_open_medium_confirm_declaration
  # if successful and re-rendering :show_declaration method if unsuccessful
  def update_declaration

    logger.info(
      'Updating declaration attributes for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    @funding_application.open_medium.validate_is_partnership = true

    if params[:open_medium].present?
      if params[:open_medium][:is_partnership].present?
        @funding_application.open_medium.validate_partnership_details = true if
            params[:open_medium][:is_partnership] == "true"
      end
    end

    if @funding_application.open_medium.update(declaration_params)

      logger.info(
        'Finished updating declaration attributes for open_medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_confirm_declaration

    else

      logger.info(
        'Validation failed when attempting to update declaration ' \
        "attributes for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show_declaration

    end

  end

  private

  def confirm_declaration_params

    params.fetch(:open_medium, {}).permit(
      :confirm_declaration,
      :user_research_declaration
    )

  end

  def declaration_params

    params.require(:open_medium).permit(
      :declaration_reasons_description,
      :keep_informed_declaration,
      :is_partnership,
      :partnership_details
    )

  end

  # Sets the standard terms of grant link to display on the declaration page
  #
  # @param [ProjectCosts] project_costs All project costs for the current
  #                                     funding application
  # @param [CashContributions] cash_contributions All cash contributions
  #                                     for the current funding application
  def set_standard_terms_link(project_costs, cash_contributions)

    if @funding_application.is_10_to_100k?

      if I18n.locale == :cy 
        @standard_terms_link = 'https://www.heritagefund.org.uk/cy/publications/' \
        'standard-terms-grants-10k-100k'
      else
        @standard_terms_link = 'https://www.heritagefund.org.uk/publications/' \
        'standard-terms-grants-10k-100k'
      end

    elsif @funding_application.is_100_to_250k?

      if I18n.locale == :cy 
        @standard_terms_link = 'https://www.heritagefund.org.uk/cy/publications/' \
        'standard-terms-grants-100k-250k'
      else
        @standard_terms_link = 'https://www.heritagefund.org.uk/publications/' \
        'standard-terms-grants-100k-250k'
      end

    end

  end

  # Caluclates the total grant request for the current funding application
  #
  # @param [ProjectCosts] project_costs All project costs for the current
  #                                     funding application
  # @param [CashContributions] cash_contributions All cash contributions
  #                                     for the current funding application
  #
  # @return [Int] The total grant request
  def calculate_grant_request_total(project_costs, cash_contributions)

    total_project_cost = helpers.calculate_total(project_costs).to_i

    total_cash_contributions = helpers.calculate_total(cash_contributions).to_i

    total_project_cost - total_cash_contributions

  end

end
