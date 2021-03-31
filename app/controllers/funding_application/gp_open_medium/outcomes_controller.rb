class FundingApplication::GpOpenMedium::OutcomesController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger

  def update

    logger.info(
      'Updating outcome attributes for open_medium ID: ' \
      "#{@funding_application.open_medium.id}"
    )

    remove_outcome_descriptions

    @funding_application.open_medium.validate_other_outcomes = true

    if @funding_application.open_medium.update(open_medium_params)

      logger.info(
        'Finished updating outcome attributes for open_medium ' \
        "ID: #{@funding_application.open_medium.id}"
      )

      redirect_to :funding_application_gp_open_medium_how_will_your_project_be_managed

    else

      logger.info(
        'Validation failed when attempting to update outcome ' \
        "attributes for open_medium ID: #{@funding_application.open_medium.id}"
      )

      log_errors(@funding_application.open_medium)

      render :show

    end

  end

  private

  def open_medium_params

    params.require(:open_medium).permit(
        :outcome_2,
        :outcome_3,
        :outcome_4,
        :outcome_5,
        :outcome_6,
        :outcome_7,
        :outcome_8,
        :outcome_9,
        :outcome_2_description,
        :outcome_3_description,
        :outcome_4_description,
        :outcome_5_description,
        :outcome_6_description,
        :outcome_7_description,
        :outcome_8_description,
        :outcome_9_description
    )

  end

  # This method sets outcome description parameters to an empty string
  # if the outcome has been unchecked on the page. This is necessary
  # as unchecking a checkbox on the page does not remove the value
  # from the corresponding conditional textfield, meaning that it still
  # gets passed in the params.
  def remove_outcome_descriptions
    if params[:open_medium].present?
      for i in 2..9
        if params[:open_medium]["outcome_#{i}"] == "false"
          params[:open_medium]["outcome_#{i}_description"] = ""
        end
      end
    end
  end

end
