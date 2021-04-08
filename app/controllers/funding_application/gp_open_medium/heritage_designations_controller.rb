class FundingApplication::GpOpenMedium::HeritageDesignationsController < ApplicationController
    include FundingApplicationContext
    include ObjectErrorsLogger
  
    # This method updates the heritage_designations attribute of an 
    # open_medium redirecting to
    # :funding_application_gp_open_medium_why_is_your_organisation_best_placed
    # if successful and re-rendering :show method if unsuccessful
    def update
  
      logger.info(
        'Updating heritage_designations for open medium ID: ' \
        "#{@funding_application.open_medium.id}"
      )

      clear_descriptions(
        @funding_application,
        params
      )
  
      @funding_application.open_medium.validate_heritage_designations = true
  
      if @funding_application.open_medium.update(open_medium_params)
  
        logger.debug(
          'Finished updating heritage_designations for open_medium ' \
          "ID: #{@funding_application.open_medium.id}"
        )
  
        redirect_to :funding_application_gp_open_medium_visitors
  
      else
  
        logger.info(
          'Validation failed when attempting to update heritage_designations ' \
          "for open_medium ID: #{@funding_application.open_medium.id}"
        )
  
        log_errors(@funding_application.open_medium)
  
        render :show
  
      end
  
    end
  
    private
  
    def open_medium_params
  
      params.fetch(:open_medium, {}).permit(
        :hd_grade_1_description,
        :hd_grade_2_b_description,
        :hd_grade_2_c_description,
        :hd_local_list_description,
        :hd_monument_description,
        :hd_historic_ship_description,
        :hd_grade_1_park_description,
        :hd_grade_2_park_description,
        :hd_grade_2_star_park_description,
        :hd_other_description,
        :heritage_designation_ids => []
      )
  
    end

    # Method to ensure that description attributes are cleared if necessary
    # and not validated. If a checkbox on the page is unchecked but there
    # is content in the accompanying description field, then the description
    # field will be cleared. This not only ensures that the field isn't
    # validated unnecessarily, but also that the description attribute
    # is updated to be empty.
    #
    # If no checkboxes are sent through, then all description attributes
    # are cleared.
    #
    # @param [FundingApplication] funding_application An instance of FundingApplication
    # @param [Params]             params              An instance of Params
    def clear_descriptions(funding_application, params)

      # Retrieve all HeritageDesignations from the database as an
      # array
      heritage_designations_array =
        HeritageDesignation.all.map { |hd| [hd.designation, hd.id] }

      # Convert the array to a hash
      heritage_designations_hash = heritage_designations_array.to_h

      if params[:open_medium][:heritage_designation_ids]

        params[:open_medium][:hd_grade_1_description] = nil unless
          params[:open_medium][:heritage_designation_ids].include?(
            heritage_designations_hash['grade_1_or_a_listed_building']
          )

        params[:open_medium][:hd_grade_2_b_description] = nil unless
          params[:open_medium][:heritage_designation_ids].include?(
            heritage_designations_hash['grade_2_star_or_b_listed_building']
          )

        params[:open_medium][:hd_grade_2_c_description] = nil unless
          params[:open_medium][:heritage_designation_ids].include?(
            heritage_designations_hash['grade_2_c_or_cs_listed_building']
          )

        params[:open_medium][:hd_local_list_description] = nil unless
          params[:open_medium][:heritage_designation_ids].include?(
            heritage_designations_hash['local_list']
          )

        params[:open_medium][:hd_monument_description] = nil unless
          params[:open_medium][:heritage_designation_ids].include?(
            heritage_designations_hash['scheduled_ancient_monument']
          )

        params[:open_medium][:hd_historic_ship_description] = nil unless
          params[:open_medium][:heritage_designation_ids].include?(
            heritage_designations_hash['registered_historic_ship']
          )

        params[:open_medium][:hd_grade_1_park_description] = nil unless
          params[:open_medium][:heritage_designation_ids].include?(
            heritage_designations_hash['grade_1_listed_park_or_garden']
          )

        params[:open_medium][:hd_grade_2_park_description] = nil unless
          params[:open_medium][:heritage_designation_ids].include?(
            heritage_designations_hash['grade_2_listed_park_or_garden']
          )

        params[:open_medium][:hd_grade_2_star_park_description] = nil unless
          params[:open_medium][:heritage_designation_ids].include?(
            heritage_designations_hash['grade_2_star_listed_park_or_garden']
          )

        params[:open_medium][:hd_other_description] = nil unless
          params[:open_medium][:heritage_designation_ids].include?(
            heritage_designations_hash['other']
          )
        
      else

        params[:open_medium][:hd_grade_1_description] = nil
        params[:open_medium][:hd_grade_2_b_description] = nil
        params[:open_medium][:hd_grade_2_c_description] = nil
        params[:open_medium][:hd_local_list_description] = nil
        params[:open_medium][:hd_monument_description] = nil
        params[:open_medium][:hd_historic_ship_description] = nil
        params[:open_medium][:hd_grade_1_park_description] = nil
        params[:open_medium][:hd_grade_2_park_description] = nil
        params[:open_medium][:hd_grade_2_star_park_description] = nil
        params[:open_medium][:hd_other_description] = nil

      end

    end
  
  end
  