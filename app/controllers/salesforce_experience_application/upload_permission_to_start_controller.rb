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
				save_submitted_on_and_form_id(pts_form_record_id)

        redirect_to(
          sfx_pts_payment_confirmation_path(
            @salesforce_experience_application.salesforce_case_id
          )
        )
      else
        render :show
      end

		# Form submitted to add a file.  Validate and act accordingly.
		elsif params.has_key?(:add_file_button) && params.has_key?(:sfx_pts_payment)
      save_files()
      @attached_pts_docs = get_attachments()
      render :show
		end

		# Form submitted to delete a file. Pass params with blob id.
		if params.has_key?(:delete_file_button)
			delete(params[:delete_file_button]) 	
    end

  end

	def delete(blob_id) 

		delete_blob(blob_id)

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
	# @param [int] pts_form_record_id The pts form record model to attach 
	# documents to. 
	def upload_to_salesforce(pts_form_record_id)
		upload_salesforce_pts_files(pts_form_record_id, 
				@salesforce_experience_application)
	end

	# Sets the submitted_on and salesforce_pts_form_record_id for an 
	# SfxPtsPayment instance.
	# Saves these attributes to the database once set 
	# 
	# @param [pts_form_record_id] String An id for the Forms__c 
	# record that was created for the permission to start form in Salesforce.
	#
	def save_submitted_on_and_form_id(pts_form_record_id)
		@salesforce_experience_application.submitted_on = Time.current
		@salesforce_experience_application.salesforce_pts_form_record_id = \
			pts_form_record_id
		@salesforce_experience_application.save
		project_ref_number = get_info_for_start_page(
      @salesforce_experience_application.salesforce_case_id)[:project_ref_no]
		NotifyMailer.pts_submission_confirmation(@salesforce_experience_application.email_address, project_ref_number).deliver_later 
	end
  
end
