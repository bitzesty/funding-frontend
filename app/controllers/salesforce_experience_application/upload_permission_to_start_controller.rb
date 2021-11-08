class SalesforceExperienceApplication::UploadPermissionToStartController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show
    @attached_pts_docs = get_attachments()
  end

  def update
    # Form submitted to save and continue.  Validate and act accordingly.
		if params.has_key?(:save_and_continue_button)

      @salesforce_experience_application.validate_pts_form_files =  true;

      if @salesforce_experience_application.valid?

				pts_form_record_id = create_pts_form_record(@salesforce_experience_application)
				upload_to_salesforce(pts_form_record_id)
				set_submitted_on()

        redirect_to(
          sfx_pts_payment_confirmation_path(
            @salesforce_experience_application.salesforce_case_id
          )
        )
      else
        render :show
      end

		elsif params.has_key?(:add_file_button) && params.has_key?(:sfx_pts_payment)
      save_files()
      @attached_pts_docs = get_attachments()
      render :show
    end
  end

  def delete 

		delete_blob(params[:blob_id])

		logger.info "Removed file for salesforce case id: " \
			"#{@salesforce_experience_application.salesforce_case_id}"

		redirect_to(
			sfx_pts_payment_upload_permission_to_start_path(
				@salesforce_experience_application.salesforce_case_id
			)
		)

	end

  private

  def get_attachments 
		@salesforce_experience_application.pts_form_files.blobs
	end

	# Saves files.  If new files are being added, then appends those.
	def save_files()

		new_files =
			params.require(:sfx_pts_payment).permit(
				:pts_form_files => []
			)

		# Clones the ActiveStorage::Blob::ActiveRecord_Associations_CollectionProxy
		# but not the contents - to cache what files are stored currently.
		existing_file_blobs = 
			get_attachments.clone

		# Assigns the new files from params to the agreed_costs_files attribute
		# over writing attachments already there		
		@salesforce_experience_application.pts_form_files = 
			new_files[:pts_form_files]

		# Now the new files have been transformed into their own
		# ActiveStorage::Blob::ActiveRecord_Associations_CollectionProxy, append
		# to the original file collection.	
		existing_file_blobs.append \
			(get_attachments)

		# Assign the updated collection back to agreed_costs_files and save
		@salesforce_experience_application.pts_form_files = existing_file_blobs
		@salesforce_experience_application.save
	end

	# Method to upload files to Salesforce using PermisionToStartHelper
	# @param [int] pts_form_record_id The pts form record model to attach documents to. 
	def upload_to_salesforce(pts_form_record_id)
		upload_salesforce_pts_files(pts_form_record_id, @salesforce_experience_application)
	end

	def set_submitted_on()
		@salesforce_experience_application.submitted_on = Time.current
		@salesforce_experience_application.save
	end
  
end
