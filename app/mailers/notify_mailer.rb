# Sends emails via GOV.UK Notify
class NotifyMailer < Mail::Notify::Mailer

  before_action { @reply_to_id = Rails.configuration.x.reply_email_guid }

  include Devise::Controllers::UrlHelpers

  # Sends a confirmation email when an applicant registers a account for the
  # first time.
  # This method is not called explicitly from within our code, Devise is a
  # gem we use to manage accounts, and its Devise that calls 
  # confirmation_instructions when the account is created.
  # Devise is directly to use NotifyMailer within its config at devise.rb
  #
  # @param record [User] An instance of User, created by the Devise gem.
  # @param token [string] A confirmation token linking a confirmation email.
  # back to a user.
  # @param opts [{}}] optional arguments provided by the Devise call.
  def confirmation_instructions(record, token, opts = {})

    template_mail('3eed6cd0-780a-4805-b5ef-79f170a1eb73',
                  to: record.email,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                      confirmation_url: confirmation_url(record, confirmation_token: token),
                      fao_email: "."
                  }
    )
  end
  
  # Sends an identical email to one sent from the confirmation_instructions
  # above.  Goes to a support mailbox with very limited access.
  # Helps support when spam filters and organisation mail settings prevent
  # applicants from getting their initial registration emails.
  #
  # @param record [User] An instance of User, created by the Devise gem.
  def confirmation_instructions_copy(record) 
    template_mail('3eed6cd0-780a-4805-b5ef-79f170a1eb73',
      to: Rails.configuration.x.no_reply_email_address,
      reply_to_id: Rails.configuration.x.reply_email_guid,
      personalisation: {
          confirmation_url: devise_confirmation_url(record, confirmation_token: record.confirmation_token),
          fao_email: " FAO - #{record.email}"
      }
    )  
  end

  # Wraps Devise's confirmation_url as it was tricky to mock in
  # notify_mailer_spec.rb
  def devise_confirmation_url(record, confirmation_token)
    confirmation_url(record, confirmation_token)
  end

  # Use ERB template as Notify does not support required templating logic.
  def email_changed(record, opts = {})
    @resource = record
    view_mail('cd9fbf07-4960-4cb7-903c-068b76d2ca32',
              reply_to_id: @reply_to_id,
              to: @resource.email,
              subject: 'Email changed'
    )
  end


  def password_change(record, opts = {})
    template_mail('32bc1da4-99aa-4fde-9124-6c423cfcab15',
                  reply_to_id: @reply_to_id,
                  to: record.email
    )
  end


  def reset_password_instructions(record, token, opts = {})
    template_mail('343c89d0-0825-4363-a2eb-6a6bbc20a50f',
                  reply_to_id: @reply_to_id,
                  to: record.email,
                  personalisation: {
                      edit_password_url: edit_password_url(record, reset_password_token: token)
                  }
    )
  end

  def unlock_instructions(record, token, opts = {})
    template_mail('8c03a7c0-e23f-484e-9543-bbde9263bd47',
                  reply_to_id: @reply_to_id,
                  to: record.email,
                  personalisation: {
                      unlock_url: unlock_url(record, unlock_token: token)
                  }
    )
  end

  #  @param [Project] project
  def project_submission_confirmation(project)
    template_mail('071cfcda-ebd4-4eba-8602-338b12edc4f9',
                  to: project.user.email,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                      project_reference_number: project.funding_application.project_reference_number
                  }
    )
  end

  def pts_submission_confirmation(email, project_reference_number)
    logger.info "Sent confirmation email to: " \
			"email #{email}"
    template_mail('24833676-a335-4e88-9fff-2470b4fe0b95',
                  to: email,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                  project_reference_number: project_reference_number
                }
      )
  end

  #  @param [PreApplication] pre_application
  def project_enquiry_submission_confirmation(pre_application)
    template_mail('34ec207b-e8d1-46be-87ee-2eca4b665cbc',
                  to: pre_application.user.email,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                      pa_project_enquiry_reference: pre_application.pa_project_enquiry.salesforce_pef_reference
                  }
    )
  end

  #  @param [PreApplication] pre_application
  def expression_of_interest_submission_confirmation(pre_application)
    template_mail('76cba30c-e91b-4fae-bffc-78ee13179b9c',
                  to: pre_application.user.email,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                      pa_expression_of_interest_reference: pre_application.pa_expression_of_interest.salesforce_eoi_reference
                  }
    )
  end

  # @param [FundingApplication] funding_application
  def payment_request_submission_confirmation(
    funding_application, investment_manager_name, investment_manager_email
  )
    template_mail(
      'e35a0532-8b51-4447-bc6d-d39f705bd24c',
      to: funding_application.organisation.users.first.email,
      reply_to_id: @reply_to_id,
      personalisation: {
        project_reference_number: funding_application.project_reference_number,
        investment_manager_name: investment_manager_name,
        investment_manager_email: investment_manager_email
      }
    )
  end

  # Method which will trigger an email from GOV.UK Notify containing a link
  # which will allow a Legal Signatory access to the legal agreement journey
  #
  # @param [String] recipient_email_address The email address to send this
  #                                         email to
  # @param [String] funding_application_id A UUID for a FundingApplication
  # @param [String] agreement_link A unique link which will allow a
  #                                LegalSignatory access to the legal agreement
  #                                journey
  # @param [String] project_title The title of a project
  # @param [String] project_reference_number A unique NLHF-assigned reference
  #                                          number for a project
  # @param [String] organisation_name The name of an organisation
  def legal_signatory_agreement_link(
    recipient_email_address,
    funding_application_id,
    agreement_link,
    project_title,
    project_reference_number,
    organisation_name, 
    fao_email
  )

    template_mail(
      '9ba83d4a-e445-4c12-9f03-545bcbca4878',
      to: recipient_email_address,
      reply_to_id: Rails.configuration.x.reply_email_guid,
      personalisation: {
        funding_application_id: funding_application_id,
        agreement_link: agreement_link,
        project_title: project_title,
        project_reference_number: project_reference_number,
        organisation_name: organisation_name,
        fao_email: fao_email
      }
    )

  end

  def report_a_problem(message, name, email)
    template_mail("4d789cc6-bd6a-499f-bae2-502b633c098b",
                  to: Rails.configuration.x.support_email_address,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                      message_body: message,
                      name: name,
                      email_address: email
                  })
  end

  def question_or_feedback(message, name, email)
    template_mail("af4e775b-5a0e-4da2-81a1-3c51dd88a07c",
                  to: Rails.configuration.x.support_email_address,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                      message_body: message,
                      name: name.present? ? name : "Name not provided",
                      email_address: email.present? ? email : "Email address not provided"
                  })
  end

end