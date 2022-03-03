class FundingApplication::ProgressAndSpend::ProgressUpdate::PhotosController < ApplicationController
  include FundingApplicationContext
  
    def show()

      get_attachments
      initialize_view

    end
  
    def update()  

      progress_update.validate_has_upload_photo = true

      progress_update.has_upload_photos =
        params[:progress_update].nil? ? nil : 
          params[:progress_update][:has_upload_photos]

      if progress_update.has_upload_photos == "true"
        progress_update.validate_progress_update_photo = true
      end
    
      answers_json = progress_update.answers_json
      answers_json[:has_upload_photos] = progress_update.has_upload_photos

      progress_update.answers_json = answers_json
      progress_update.save

      if params.has_key?(:save_and_continue_button)
        if progress_update.valid?
          #TODO: FORM VALID NAVIGATE TO NEXT PAGE
        end
        rerender
      end

      # Form submitted to delete a file. 
      if params.has_key?(:delete_file_button)
        delete(params[:delete_file_button]) 
      end

      # Form submitted to add a file.
      if params.has_key?(:add_file_button)
        progress_update.update( get_params )
        rerender
      end
    end

    private

    def initialize_view()
      if  progress_update.answers_json["has_upload_photos"] == true.to_s
        progress_update.has_upload_photos = true.to_s
      elsif  progress_update.answers_json["has_upload_photos"] == false.to_s
        progress_update.has_upload_photos = false.to_s
      end
    end

    def rerender()
        initialize_view
        get_attachments
        render :show
    end
   
    def progress_update
      @funding_application.arrears_journey_tracker.progress_update
    end

    def get_attachments
      @attachments =  @funding_application.arrears_journey_tracker.progress_update
        .progress_update_photo
    end

    def delete(progress_photo_id)
      progress_update_photo =  @funding_application.arrears_journey_tracker
        .progress_update.progress_update_photo.find(progress_photo_id)
      progress_update_photo.destroy
  
      logger.info "Removed progress_update_photo with id: " \
        "#{progress_photo_id} for progress update " \
          "#{@funding_application.arrears_journey_tracker.progress_update.id}"

      redirect_to(
        funding_application_progress_and_spend_progress_update_photos_path(
          progress_update_id:  \
            @funding_application.arrears_journey_tracker.progress_update.id
        )
      )

    end

    def get_params
      params.fetch(:progress_update, {}).permit(
        progress_update_photo_attributes:[
          :progress_updates_photo_files
        ]
      )
    end
    
  end
