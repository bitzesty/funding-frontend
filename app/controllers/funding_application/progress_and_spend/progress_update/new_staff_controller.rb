class FundingApplication::ProgressAndSpend::ProgressUpdate::NewStaffController < ApplicationController
  include FundingApplicationContext

  def show()
    get_attachments
    initialize_view
  end

  def update()
    progress_update.validate_has_upload_new_staff = true

    progress_update.has_upload_new_staff =
      params[:progress_update].nil? ? nil : 
        params[:progress_update][:has_upload_new_staff]

    if progress_update.has_upload_new_staff == "true"
      progress_update.validate_progress_update_new_staff = true
    end

    if params.has_key?(:save_and_continue_button)
      save_json
      if progress_update.valid?
        # TODO: Redirect to next page
      else
        rerender
      end
    end

    # Form submitted to delete a file. 
    if params.has_key?(:delete_file_button)
      delete(params[:delete_file_button]) 
    end

    # Form submitted to add a file.
    if params.has_key?(:add_file_button)
      save_json
      progress_update.update( get_params )
      rerender
    end
  end

  private

  def initialize_view()
    if  progress_update.answers_json['new_staff']['has_new_staff'] == true.to_s
      progress_update.has_upload_new_staff = true.to_s
    elsif  progress_update.answers_json['new_staff']['has_new_staff'] == false.to_s
      progress_update.has_upload_new_staff = false.to_s
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
    @attachments_hash = Hash.new
    @funding_application.arrears_journey_tracker.progress_update
      .progress_update_new_staff&.map{ |attachment|  @attachments_hash[attachment.id] = attachment.progress_updates_new_staff_files_blob}
  end

  def delete(progress_event_id)
    save_json
    progress_update_event =  @funding_application.arrears_journey_tracker
      .progress_update.progress_update_new_staff.find(progress_event_id)
    progress_update_event.destroy

    logger.info "Removed progress_update_event with id: " \
      "#{progress_event_id} for progress update " \
        "#{@funding_application.arrears_journey_tracker.progress_update.id}"

    redirect_to(
      funding_application_progress_and_spend_progress_update_new_staff_path(
        progress_update_id:  \
          @funding_application.arrears_journey_tracker.progress_update.id
      )
    )

  end

  def get_params
    params.fetch(:progress_update, {}).permit(
      progress_update_new_staff_attributes:[
        :progress_updates_new_staff_files
      ]
    )
  end

  def save_json()
    answers_json = progress_update.answers_json
    answers_json['new_staff']['has_new_staff'] = progress_update.has_upload_new_staff

    progress_update.answers_json = answers_json
    progress_update.save
  end 
end
