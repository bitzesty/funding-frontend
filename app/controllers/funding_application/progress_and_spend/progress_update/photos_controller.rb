class FundingApplication::ProgressAndSpend::ProgressUpdate::PhotosController < ApplicationController
  include FundingApplicationContext
  
    def show()

      get_attachments

    end
  
    def update()  

      # Form submitted to delete a file. 
      if params.has_key?(:delete_file_button)
        delete(params[:delete_file_button]) 
      end

      # Form submitted to add a file.
      if params.has_key?(:add_file_button)

        # for each file in params do...
        params[:progress_update][:progress_updates_photo_files].each do |file|
          ProgressUpdatePhoto.create(progress_updates_photo_files: file, 
            progress_update_id: \
              @funding_application.arrears_journey_tracker.progress_update.id)

        end

        get_attachments

        render :show
       
      end

    end

    def get_attachments
      @attachments = ProgressUpdatePhoto.where(progress_update_id: \
          @funding_application.arrears_journey_tracker.progress_update.id)
    end

    def delete(progress_photo_id)

      ProgressUpdatePhoto.find(progress_photo_id).destroy
  
      logger.info "Removed progress_update_photo with id: " \
        "#{progress_photo_id} for progress update " \
          "#{@funding_application.arrears_journey_tracker.progress_update.id}"
  
      # If the file list is now empty, protect against the applicant url
      # manipulating to continue with this answer and no files.
      # clear_pts_answers_json_for_key(:has_agreed_costs_docs) if
      #   @salesforce_experience_application.agreed_costs_files.empty?
  
      redirect_to(
        funding_application_progress_and_spend_progress_update_photos_path(
          progress_update_id:  \
            @funding_application.arrears_journey_tracker.progress_update.id
        )
      )

    end
    
  end

