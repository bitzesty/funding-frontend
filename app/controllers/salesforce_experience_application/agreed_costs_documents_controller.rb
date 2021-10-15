# Todo - if the reusable functions created by the other file uploaders work
# then update this controller so that the functions are more testable.

class SalesforceExperienceApplication::AgreedCostsDocumentsController < ApplicationController
	include SfxPtsPaymentContext
	include PermissionToStartHelper

	def show
		@attached_agreed_docs = get_attachments()

		if @salesforce_experience_application.pts_answers_json.has_key?("has_uploaded_cost_breakdown")
			@salesforce_experience_application.has_agreed_costs_docs = 
				@salesforce_experience_application.pts_answers_json["has" \
				"_uploaded_cost_breakdown"] == 'true'
		end
	
	end

	def update

		# Form submitted to save and continue.  Validate and act accordingly.
		if params.has_key?(:save_and_continue_button)

			logger.info(
				'Save and continue clicked on agreed_costs_docs for case ID:' \
					"#{@salesforce_experience_application.salesforce_case_id}"
			)

			@salesforce_experience_application.validate_has_agreed_costs_docs = true

			@salesforce_experience_application.has_agreed_costs_docs = 
				params[:sfx_pts_payment].nil? ? nil : params[:sfx_pts_payment][:has_agreed_costs_docs]

			# validate for files if applicant indicates they will upload some.
			@salesforce_experience_application.validate_agreed_costs_files = 
				@salesforce_experience_application.has_agreed_costs_docs == 'true'

			if @salesforce_experience_application.valid?
		
				json_answers = @salesforce_experience_application.pts_answers_json
	
				json_answers[:has_uploaded_cost_breakdown] = 
					@salesforce_experience_application.has_agreed_costs_docs
	
				@salesforce_experience_application.pts_answers_json = json_answers
				@salesforce_experience_application.save

				clear_all_attachments() if @salesforce_experience_application.has_agreed_costs_docs == 'false' 

				redirect_to(
					sfx_pts_payment_cash_contributions_correct_path(@salesforce_experience_application.salesforce_case_id)
				)

			else

				@attached_agreed_docs = get_attachments()

				render :show
	
			end

		end

		# Form submitted to add a file.  Validate and act accordingly.
		if params.has_key?(:add_file_button)

			logger.info(
					'Updating agreed_costs_files for salesforce case ID:' \
					"#{@salesforce_experience_application.salesforce_case_id}"
			)

			@salesforce_experience_application.has_agreed_costs_docs = 
				params[:sfx_pts_payment].nil? ? nil : params[:sfx_pts_payment][:has_agreed_costs_docs]

			if save_files()
				logger.info(
					'Finished updating agreed costs files for ' \
					"for salesforce case ID:' #{@salesforce_experience_application.salesforce_case_id}"
				)
		
			end
				
			@attached_agreed_docs = get_attachments()

			render :show

		end

	end


	# Saves files.  If new files are being added, then appends those.
  #        
	def save_files()

		new_files =
			params.require(:sfx_pts_payment).permit(
				:has_agreed_costs_docs,:agreed_costs_files => []
			)

		# Clones the ActiveStorage::Blob::ActiveRecord_Associations_CollectionProxy
		# but not the contents - to cache what files are stored currently.
		existing_file_blobs = 
			get_attachments.clone

		# Assigns the new files from params to the agreed_costs_files attribute
		# over writing attachments already there		
		@salesforce_experience_application.agreed_costs_files = 
			new_files[:agreed_costs_files]

		# Now the new files have been transformed into their own
		# ActiveStorage::Blob::ActiveRecord_Associations_CollectionProxy, append
		# to the original file collection.	
		existing_file_blobs.append \
			(get_attachments)

		# Assign the updated collection back to agreed_costs_files and save
		@salesforce_experience_application.agreed_costs_files = existing_file_blobs
		@salesforce_experience_application.save

	end

	def delete 

		delete_blob(params[:blob_id])

		logger.info "Removed file for salesforce case id: " \
			"#{@salesforce_experience_application.salesforce_case_id}"
		
		@attached_agreed_docs = get_attachments()

		redirect_to(
			sfx_pts_payment_agreed_costs_documents_path(@salesforce_experience_application.salesforce_case_id)
		)

	end

	private

	def get_attachments 
		@salesforce_experience_application.agreed_costs_files.blobs
	end

	def clear_all_attachments
		@salesforce_experience_application.agreed_costs_files.purge
	end

end