class FundingApplication::GpOpenMedium::CashContributionsController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  # This method is used to set the @has_file_upload instance variable before
  # rendering the :show template. This is used within the
  # _direct_file_upload_hooks partial
  def show

    @has_file_upload = true

    # Empty flash values to ensure that we don't redisplay them unnecessarily
    flash[:description] = ""
    flash[:amount] = ""
    flash[:secured] = ""

  end

  # This method is used to control navigational flow after a user
  # has submitted the 'Are you getting any cash contributions?' form,
  # redirecting based on @funding_application.cash_contributions_question value, and
  # re-rendering :question if unsuccessful
  def question_update

    logger.info(
      'Updating cash contributions question for funding_application ID: ' \
      "#{@funding_application.id}"
    )

    @funding_application.validate_cash_contributions_question = true

    if @funding_application.update(question_params)

      logger.info(
        'Finished updating cash contributions question for ' \
        "funding_application ID: #{@funding_application.id}"
      )

      if @funding_application.cash_contributions_question == 'true'

        redirect_to :funding_application_gp_open_medium_cash_contributions

      else

        redirect_to :funding_application_gp_open_medium_your_grant_request

      end

    else

      logger.info(
        'Validation failed for cash contributions question for ' \
        "funding_application ID: #{@funding_application.id}"
      )

      log_errors(@funding_application)

      render :question

    end

  end

  # This method adds a cash contribution to a funding_application, redirecting
  # back to :funding_application_gp_open_medium_cash_contributions if
  # successful and re-rendering :show method if unsuccessful
  def update

    # Empty flash values to ensure that we don't redisplay them unnecessarily
    flash[:description] = ""
    flash[:amount] = ""
    flash[:secured] = ""

    logger.info(
      'Adding cash contribution for funding_application ID: ' \
      "#{@funding_application.id}"
    )

    @funding_application.validate_cash_contributions = true

    if @funding_application.update(funding_application_params)

      logger.info(
        'Successfully added cash contribution for funding_application ' \
        "ID: #{@funding_application.id}"
      )

      redirect_to :funding_application_gp_open_medium_cash_contributions

    else

      logger.info(
        'Validation failed when attempting to add a cash ' \
        "contribution for funding_application ID: #{@funding_application.id}"
      )

      log_errors(@funding_application)

      flash[:description] =
        params['funding_application']['cash_contributions_attributes']['0']['description']
      flash[:amount] =
        params['funding_application']['cash_contributions_attributes']['0']['amount']
      flash[:secured] =
        params['funding_application']['cash_contributions_attributes']['0']['secured']

      render :show

    end

  end

  # This method deletes a cash contribution, redirecting back to
  # :funding_application_gp_open_medium_cash_contributions once completed.
  # If no cash contribution is found, then an ActiveRecord::RecordNotFound
  # exception is raised
  def delete

    logger.info(
      'User has selected to delete cash contribution ID: ' \
      "#{params[:cash_contribution_id]} from funding_application ID: " \
      "#{@funding_application.id}"
    )

    cash_contribution =
        @funding_application.cash_contributions.find(params[:cash_contribution_id])

    link_record = FundingApplicationsCc.find_by(
      cash_contribution_id: params[:cash_contribution_id]
    )

    logger.info("Deleting funding_applications_ccs ID: #{ link_record.id }")

    link_record.destroy

    logger.info(
      'Finished deleting funding_applications_ccs ID: ' \
      "#{ link_record.id }"
    )

    logger.info "Deleting cash contribution ID: #{cash_contribution.id}"

    cash_contribution.destroy

    logger.info(
      'Finished deleting cash contribution ID: ' \
      "#{cash_contribution.id}"
    )

    redirect_to :funding_application_gp_open_medium_cash_contributions

  end

  private

  def question_params

    params.fetch(:funding_application, {}).permit(
      :cash_contributions_question
    )

  end

  def funding_application_params

    params.require(:funding_application).permit(
      cash_contributions_attributes: [
        :description,
        :secured,
        :amount,
        :cash_contribution_evidence_files
      ]
    )

  end

end
