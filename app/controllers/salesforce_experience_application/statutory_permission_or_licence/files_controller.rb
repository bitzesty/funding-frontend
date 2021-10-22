class SalesforceExperienceApplication::StatutoryPermissionOrLicence::FilesController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show
    initialise_view_attributes
  end

  def update

    @statutory_permission_or_licence = StatutoryPermissionOrLicence.find(
      params[:statutory_permission_or_licence_id]
    )

    # clear previous answers, otherwise can they show when rendering error page
    clear_statutory_permissions_or_licences_json_for_key(
      @statutory_permission_or_licence,
      :upload_question
    )

    # Form submitted to save and continue.  Validate and act accordingly.
		if params.has_key?(:save_and_continue_button)

      if validate_and_store_answers(params)

        logger.info(
          'File info updated for statutory_permission_or_licence_id: ' \
            "#{@statutory_permission_or_licence.id} " \
              "for sfx_pts_payment_id: #{@salesforce_experience_application.id}"
        )

        redirect_to(
          sfx_pts_payment_statutory_permission_or_licence_summary_path(
            @salesforce_experience_application.salesforce_case_id)
        )

      else
        initialise_view_attributes
        render :show
      end

    end

    # Form submitted to add a file.  Validate and act accordingly.
		if params.has_key?(:add_file_button)
      validate_and_store_files(params)
    end

  end

  # deletes an attachment
  # queries params and deletes by blob id
  def delete 

    @statutory_permission_or_licence = StatutoryPermissionOrLicence.find(
      params[:statutory_permission_or_licence_id]
    )

		delete_blob(params[:blob_id])

		logger.info "Removed file from statutory_permission_or_licence.id: " \
			"#{@statutory_permission_or_licence.id}"

    # If the file list is now empty, protect against the applicant url
    # manipulating to continue with this answer and no files.
    clear_statutory_permissions_or_licences_json_for_key(
      @statutory_permission_or_licence,
      :upload_question
    ) if @statutory_permission_or_licence.upload_files.empty?

    redirect_to(
      sfx_pts_payment_statutory_permission_or_licence_files_path(
        @salesforce_experience_application.salesforce_case_id, 
          @statutory_permission_or_licence.id
      )
    )

	end

  private

    # Method to validate answers and store if valid
    # Also show applicant error if they selected file
    # Upload bullet without selecting a file
    #
    # @param [ActionController::Parameters] params Set of params from view.
    # @return [Boolean] result returns true if valid and stored.
    def validate_and_store_answers(params)

      result = false

      logger.info(
				'Save and continue clicked on upload file ' \
          'for statutory_permission_or_licence.id:' \
					  "#{@statutory_permission_or_licence.id}"
			)

			@statutory_permission_or_licence.validate_upload_question = true

			@statutory_permission_or_licence.upload_question = 
				params[:statutory_permission_or_licence].nil? ? nil : \
          params[:statutory_permission_or_licence][:upload_question]

			# validate for files if applicant indicates they will upload some.
			@statutory_permission_or_licence.validate_upload_files = 
				@statutory_permission_or_licence.upload_question == 
          t('salesforce_experience_application.' \
            'statutory_permission_or_licence.files.bullets.i_will_upload')

			if @statutory_permission_or_licence.valid?

        update_statutory_permissions_or_licences_json(
          @statutory_permission_or_licence,
          :upload_question, 
          @statutory_permission_or_licence.upload_question
        )

        # clear attachments if the file upload bullet not chosen
        clear_all_attachments unless
          @statutory_permission_or_licence.validate_upload_files?

        result = true

      end

      result

    end

    # Validates and stores files
    # Upon successful file saving, store that the applicant has
    # selected the file upload bullet.
    # Then re-render the page to show the new file
    def validate_and_store_files(params)

      logger.info(
        'Updating upload_files for statutory_permission_or_licence.id:' \
          "#{@statutory_permission_or_licence.id}"
      )

      if save_files()
        logger.info(
          'Finished updating upload_files for ' \
            "statutory_permission_or_licence.id:' "\
              "#{@statutory_permission_or_licence.id}"
        )
    
      end

      @statutory_permission_or_licence.upload_question = 
        t('salesforce_experience_application.' \
          'statutory_permission_or_licence.files.bullets.i_will_upload')

      update_statutory_permissions_or_licences_json(
        @statutory_permission_or_licence,
        :upload_question, 
        @statutory_permission_or_licence.upload_question
      )

      initialise_view_attributes
      render :show

    end

  # Saves files.  If new files are being added, then appends those.
	def save_files()

		new_files =
			params[:statutory_permission_or_licence][:upload_files]

		# Clones the ActiveStorage::Blob::ActiveRecord_Associations_CollectionProxy
		# but not the contents - to cache what files are stored currently.
		existing_file_blobs = 
			get_attachments.clone

		# Assigns the new files from params to the agreed_costs_files attribute
		# over writing attachments already there
		@statutory_permission_or_licence.upload_files = 
      new_files

		# Now the new files have been transformed into their own
		# ActiveStorage::Blob::ActiveRecord_Associations_CollectionProxy, append
		# to the original file collection.	
		existing_file_blobs.append \
			(get_attachments)

		# Assign the updated collection back to agreed_costs_files and save
		@statutory_permission_or_licence.upload_files = 
      existing_file_blobs
		@statutory_permission_or_licence.save

	end

  # initialises the attributes needed to correctly display the form.
  # Then gets file attachments
  # Handles an ActiveRecord::RecordNotFound in case applicant deletes
  # @statutory_permission_or_licence on the summary page - then hits back
  # sets the appropriate radio button
  # will show the file upload radio button if model has file errors.
  def initialise_view_attributes

    # overwriting @statutory_permission_or_licence, when present, will clear 
    # errors.  Instead find it.
    begin
      @statutory_permission_or_licence = StatutoryPermissionOrLicence.find(
        params[:statutory_permission_or_licence_id]
      ) unless @statutory_permission_or_licence.present?

      @files = get_attachments()

      # initialise select_file_upload_radio
      select_file_upload_radio = false

      # set 
      @statutory_permission_or_licence.upload_question = 
        @statutory_permission_or_licence.details_json[
          :upload_question.to_s
        ] 
  
      # on file upload errors - always populate file upload radio
      @statutory_permission_or_licence.errors.any? do |error|
        select_file_upload_radio = error.attribute == :upload_files
      end
  
      if select_file_upload_radio
  
        @statutory_permission_or_licence.upload_question =
          t('salesforce_experience_application.' \
            'statutory_permission_or_licence.files.bullets.i_will_upload')
      end

    rescue ActiveRecord::RecordNotFound
      redirect_to(
        sfx_pts_payment_permissions_or_licences_path(
          @salesforce_experience_application.salesforce_case_id
        )
      )
    end

  end

  # get the attachments to show in the view and to append new files.
  def get_attachments 
    @statutory_permission_or_licence&.upload_files&.blobs
  end

  # clears all the attachments.  Used when the applicant uploads files, then
  # chooses another bullet that does not use files.
  def clear_all_attachments
    @statutory_permission_or_licence.upload_files.purge
  end

end
