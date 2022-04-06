class FundingApplication::ProgressAndSpend::ProgressUpdate::\
  NewExpiryDateController < ApplicationController
    include FundingApplicationContext
  
    def show()
      @new_expiry_date = get_new_expiry_date
      populate_day_month_year(@new_expiry_date)
    end
  
    def update()

      @new_expiry_date = get_new_expiry_date

      assign_complete_date_param(@new_expiry_date, params)

      @new_expiry_date.update(permitted_params(params))

      unless @new_expiry_date.errors.any?

        redirect_to(
          funding_application_progress_and_spend_progress_update_permissions_or_licences_path(
              progress_update_id:
                @funding_application.arrears_journey_tracker.progress_update.id
          )
        )

      else

        render :show

      end

    end

    private

    # Returns the permitted params
    #
    # @params [ActionController::Parameters] params A hash of params
    # @return [ActionController::Parameters] params A hash of filtered params
    def permitted_params(params)
      params.fetch('progress_update_new_expiry_date').permit(
        :date_day, :date_month, :date_year, :full_date, :description
      )
    end

    # Gets an instance of new_expiry_date
    # Checks to see if an instance exists, and returns if so.
    # otherwise builds an in memory instance and returns
    # @return [ProgressUpdateNewExpiryDate]
    def get_new_expiry_date

      progress_update =  @funding_application.arrears_journey_tracker.progress_update

      progress_update.progress_update_new_expiry_date.first.nil? ? \
        progress_update.progress_update_new_expiry_date.build : \
          progress_update.progress_update_new_expiry_date.first

    end
    
    # Gets the day, month, year params and populates model with them
    # Uses model validation to see if the supplied info makes a valid date
    # If supplied info valid, create a date object from it
    # then include that date in the supplied params for later update.
    #
    # @params [ProgressUpdateNewExpiryDate] expiry_date
    # @params [ActionController::Parameters] params Unfiltered params
    def assign_complete_date_param(expiry_date, params)

      pp = permitted_params(params)

      expiry_date.date_day = pp[:date_day].to_i
      expiry_date.date_month = pp[:date_month].to_i
      expiry_date.date_year = pp[:date_year].to_i
    
      if expiry_date.valid?
        params[:progress_update_new_expiry_date][:full_date] = DateTime.new(
          expiry_date.date_year, 
          expiry_date.date_month, 
          expiry_date.date_day 
        )
      end

    end

    # Allows returning applicants to see the date they added first time
    # Parses date, if found, and populates day, month, year fields
    #
    # @param [ProgressUpdateNewExpiryDate] new_expiry_date
    def populate_day_month_year(new_expiry_date)

      full_date = new_expiry_date&.full_date

      if full_date.present?
        new_expiry_date.date_day = full_date.day
        new_expiry_date.date_month = full_date.month
        new_expiry_date.date_year = full_date.year
      end

    end
  
  end
