class FundingApplication::GpOpenMedium::NonCashContributionsController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method is used to control navigational flow after a user
  # has submitted the 'Are you getting any non-cash contributions?' form,
  # redirecting based on @funding_application.non_cash_contributions_question
  # value, and re-rendering :question if unsuccessful
  def question_update

    logger.info(
      'Updating non-cash contributions question for funding_application ' \
      "ID: #{@funding_application.id}"
    )

    @funding_application.validate_non_cash_contributions_question = true

    if @funding_application.update(question_params)

      logger.info(
        'Finished updating non-cash contributions question for ' \
        "funding_application ID: #{@funding_application.id}"
      )

      if @funding_application.non_cash_contributions_question == 'true'

        redirect_to :funding_application_gp_open_medium_non_cash_contributions

      else

        redirect_to :funding_application_gp_open_medium_volunteers

      end

    else

      logger.info(
        'Validation failed when attempting to update non-cash contributions' \
        " question for funding_application ID: #{@funding_application.id}"
      )

      log_errors(@funding_application)

      render :question

    end

  end

  # This method adds a non-cash contribution to a funding_application,
  # redirecting back to
  # :funding_application_gp_open_medium_non_cash_contributions
  # if successful and re-rendering :show method if unsuccessful
  def update

    # Empty flash values to ensure that we don't redisplay them unnecessarily
    flash[:description] = ""
    flash[:amount] = ""

    logger.info(
      'Adding non-cash contribution for funding_application ID: ' \
      "#{@funding_application.id}"
    )

    # @funding_application.validate_non_cash_contributions = true

    if @funding_application.update(funding_application_params)

      logger.info(
        'Successfully added non-cash contribution for funding_application ' \
        "ID: #{@funding_application.id}"
      )

      redirect_to :funding_application_gp_open_medium_non_cash_contributions

    else

      logger.info(
        'Validation failed when attempting to add a non-cash ' \
        "contribution for funding_application ID: #{@funding_application.id}"
      )

      log_errors(@funding_application)

      # Store flash values to display them again when re-rendering the page
      flash[:description] =
          params['funding_application']['non_cash_contributions_attributes']['0']['description']
      flash[:amount] =
          params['funding_application']['non_cash_contributions_attributes']['0']['amount']

      render :show

    end

  end

  # This method deletes a non_cash_contribution and the associated link table
  # record redirecting back to
  # :funding_application_open_medium_non_cash_contributions once completed
  def delete

    logger.info(
      'User has selected to delete non_cash_contribution ID: ' \
      "#{params[:non_cash_contribution_id]} from funding_application ID: " \
      "#{@funding_application.id}"
    )

    non_cash_contribution = @funding_application.non_cash_contributions.find(
      params[:non_cash_contribution_id]
    )

    link_record = FundingApplicationsNcc.find_by(
      non_cash_contribution_id: params[:non_cash_contribution_id]
    )

    logger.info("Deleting funding_applications_nccs ID: #{ link_record.id }")

    link_record.destroy

    logger.info(
      'Finished deleting funding_applications_nccs ID: ' \
      "#{ link_record.id }"
    )

    logger.info(
      "Deleting non_cash_contribution ID: #{non_cash_contribution.id}"
    )

    non_cash_contribution.destroy

    logger.info(
      "Finished deleting non_cash_contribution ID: #{non_cash_contribution.id}"
    )

    redirect_to :funding_application_gp_open_medium_non_cash_contributions

  end

  private

  def question_params

    params.fetch(:funding_application, {}).permit(
      :non_cash_contributions_question
    )

  end

  def funding_application_params

    params.fetch(:funding_application, {}).permit(
      non_cash_contributions_attributes: [
        :description,
        :amount
      ]
    )

  end

end
