class SalesforceExperienceApplication::PropertyOwnershipEvidenceController < ApplicationController
  include SfxPtsPaymentContext
  include PermissionToStartHelper

  def show
    initialise_view_attributes
  end

  def update

    # clear previous answers, otherwise can they show when rendering error page
    clear_pts_answers_json_for_key(:property_ownership_evidence_question)

    # Form submitted to save and continue.  Validate and act accordingly.
		if params.has_key?(:save_and_continue_button)

      if validate_and_store_answers(params)
        redirect_to(
          sfx_pts_payment_permissions_or_licences_path(
            @salesforce_experience_application.salesforce_case_id
          )
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

		delete_blob(params[:blob_id])

		logger.info "Removed file for salesforce case id: " \
			"#{@salesforce_experience_application.salesforce_case_id}"

    # If the file list is now empty, protect against the applicant url
    # manipulating to continue with this answer and no files.
    clear_pts_answers_json_for_key(:property_ownership_evidence_question) if
      @salesforce_experience_application.property_ownership_evidence_files.empty?

		redirect_to(
			sfx_pts_payment_property_ownership_evidence_path(
        @salesforce_experience_application.salesforce_case_id
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
				'Save and continue clicked on upload evidence of ownership ' \
          'for case ID:' \
					  "#{@salesforce_experience_application.salesforce_case_id}"
			)

			@salesforce_experience_application.validate_property_ownership_evidence_question = true

			@salesforce_experience_application.property_ownership_evidence_question = 
				params[:sfx_pts_payment].nil? ? nil : \
          params[:sfx_pts_payment][:property_ownership_evidence_question]

			# validate for files if applicant indicates they will upload some.
			@salesforce_experience_application.validate_property_ownership_evidence_files = 
				@salesforce_experience_application.property_ownership_evidence_question == 
          t('salesforce_experience_application.property_ownership_evidence.bullets.' \
            'i_will_upload')

			if @salesforce_experience_application.valid?

        update_pts_answers_json(
          :property_ownership_evidence_question, 
            @salesforce_experience_application.property_ownership_evidence_question
        )

        # clear attachments if the file upload bullet not chosen
        clear_all_attachments unless
          @salesforce_experience_application.validate_property_ownership_evidence_files?

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
        'Updating property_ownership_evidence_files for salesforce case ID:' \
        "#{@salesforce_experience_application.salesforce_case_id}"
      )

      if save_files()
        logger.info(
          'Finished updating property_ownership_evidence_files for ' \
          "for salesforce case ID:' "\
            "#{@salesforce_experience_application.salesforce_case_id}"
        )
    
      end

      @salesforce_experience_application.property_ownership_evidence_question = 
        t('salesforce_experience_application.' \
          'property_ownership_evidence.bullets.i_will_upload')

      update_pts_answers_json(
        :property_ownership_evidence_question, 
        @salesforce_experience_application.property_ownership_evidence_question
      )

      initialise_view_attributes
      render :show

    end

  # Saves files.  If new files are being added, then appends those.
	def save_files()

		new_files =
			params[:sfx_pts_payment][:property_ownership_evidence_files]

		# Clones the ActiveStorage::Blob::ActiveRecord_Associations_CollectionProxy
		# but not the contents - to cache what files are stored currently.
		existing_file_blobs = 
			get_attachments.clone

		# Assigns the new files from params to the agreed_costs_files attribute
		# over writing attachments already there
		@salesforce_experience_application.property_ownership_evidence_files = 
      new_files

		# Now the new files have been transformed into their own
		# ActiveStorage::Blob::ActiveRecord_Associations_CollectionProxy, append
		# to the original file collection.	
		existing_file_blobs.append \
			(get_attachments)

		# Assign the updated collection back to agreed_costs_files and save
		@salesforce_experience_application.property_ownership_evidence_files = 
      existing_file_blobs
		@salesforce_experience_application.save

	end

  # initialises the attributes needed to correctly display the form.
  # get the files attachments
  # sets the appropriate radio button
  # will show the file upload radio button if model has file errors.
  def initialise_view_attributes

    @files = get_attachments()

    select_file_upload_bullet = false

    @salesforce_experience_application.errors.any? do |error|
      select_file_upload_bullet = (
        error.attribute == :property_ownership_evidence_files
      )
    end

    if select_file_upload_bullet

      @salesforce_experience_application.cash_contributions_evidence_question =
      t('salesforce_experience_application.' \
        'property_ownership_evidence_files.bullets.i_will_upload')

    else

      @salesforce_experience_application.property_ownership_evidence_question = 
        @salesforce_experience_application.pts_answers_json[
          :property_ownership_evidence_question.to_s
        ]

    end

  end

  # get the attachments to show in the view and to append new files.
  def get_attachments 
    @salesforce_experience_application.property_ownership_evidence_files.blobs
  end

  # clears all the attachments.  Used when the applicant uploads files, then
  # chooses another bullet that does not use files.
  def clear_all_attachments
    @salesforce_experience_application.property_ownership_evidence_files.purge
  end

end
