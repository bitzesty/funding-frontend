# Sends emails via GOV.UK Notify
class NotifyMailer < Mail::Notify::Mailer

  before_action { @reply_to_id = Rails.configuration.x.reply_email_guid }

  include Devise::Controllers::UrlHelpers


  # Sends a confirmation email when an applicant registers an account for the
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

    template_mail('cccbf9f4-a633-453e-9b32-24f1c86879ec',
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
    template_mail('cccbf9f4-a633-453e-9b32-24f1c86879ec',
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
    template_mail('264362fc-cb45-4ec1-8e57-96f0212cc3bb',
                  reply_to_id: @reply_to_id,
                  to: record.email
    )
  end


  def reset_password_instructions(record, token, opts = {})
    template_mail('62886d47-0c06-4019-b09a-1ff1df9101fe',
                  reply_to_id: @reply_to_id,
                  to: record.email,
                  personalisation: {
                      edit_password_url: edit_password_url(record, reset_password_token: token)
                  }
    )
  end

  def unlock_instructions(record, token, opts = {})
    template_mail('cd9ae6dc-14d7-43d3-b019-90c1ab9fdad0',
                  reply_to_id: @reply_to_id,
                  to: record.email,
                  personalisation: {
                      unlock_url: unlock_url(record, unlock_token: token)
                  }
    )
  end

  #  @param [string] email Email of the applicant
  #  @param [string] reference Reference of the the gp_project
  #  @param [string] template_id ID of the template to br used
  def project_submission_confirmation(email, reference, template_id)
    template_mail(template_id,
                  to: email,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                      project_reference_number: reference
                  }
    )
  end

  def pts_submission_confirmation(email, project_reference_number, template_id)
    logger.info "Sent confirmation email to: " \
			"email #{email}"
    template_mail(template_id,
                  to: email,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                  project_reference_number: project_reference_number
                }
      )
  end

  # @param [string] email email address of applicant
  # @param [string] reference reference for the pef
  # @param [string] template_id Notify template id
  def project_enquiry_submission_confirmation(email, reference, template_id)
    template_mail(template_id,
                  to: email,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                      pa_project_enquiry_reference: reference
                  }
    )
  end

  # @param [string] email email address of applicant
  # @param [string] reference reference for the pef
  # @param [string] template_id Notify template id
  def expression_of_interest_submission_confirmation(email, reference, template_id)
    template_mail(template_id,
                  to: email,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                      pa_expression_of_interest_reference: reference
                  }
    )
  end

  # @param [FundingApplication] funding_application
  def payment_request_submission_confirmation(
    email,
    project_reference_number,
    investment_manager_name,
    investment_manager_email,
    template_id
  )
    template_mail(
      template_id,
      to: email,
      reply_to_id: @reply_to_id,
      personalisation: {
        project_reference_number: project_reference_number,
        investment_manager_name: investment_manager_name,
        investment_manager_email: investment_manager_email
      }
    )
  end

  # @param [string] email email address of applicant
  # @param [string] reference reference for the pef
  # @param [string] payment_amount payment amount
  # @param [string] ffty_prcnt_prjct_cst 50 percent payment cost
  # @param [string] template_id Notify template id
  def dev_to_100k_payment_request_confirmation(
    email, 
    reference, 
    payment_amount,
    ffty_prcnt_prjct_cst,
    template_id
  )

    template_mail(
      template_id,
      to: email,
      reply_to_id: @reply_to_id,
      personalisation: {
        project_reference_number: reference,
        payment_amount: payment_amount,
        ffty_prcnt_prjct_cst: ffty_prcnt_prjct_cst
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
  def email_with_signatory_link(
    recipient_email_address,
    funding_application_id,
    agreement_link,
    project_title,
    project_reference_number,
    organisation_name, 
    fao_email,
    template_id
  )

    template_mail(
      template_id,
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

  def report_a_problem(message, name, email, template_id)
    template_mail(template_id,
                  to: Rails.configuration.x.support_email_address,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                      message_body: message,
                      name: name,
                      user_email_address: email
                  })
  end

  def question_or_feedback(message, name, email, template_id)
    
    template_mail(template_id,
                  to: Rails.configuration.x.support_email_address,
                  reply_to_id: @reply_to_id,
                  personalisation: {
                      message_body: message,
                      name: name.present? ? name : "Name not provided",
                      user_email_address: email.present? ? email : "Email address not provided"
                  })
  end

  # Send payment request emails following an arrears journey
  # @param [String] email
  # @param [String] project_title
  # @param [String] project_reference_number
  # @param [String] payment_amount as a currency string
  # @param [String] template_id GOV.UK guid for reqd template
  def arrears_payment_request_submisson_confirmation(email, project_title, project_reference_num,
    payment_amount, template_id)

    logger.info "Sent arrears_payment_request_submisson_confirmation " \
      "email to: #{email}"

    template_mail(
      template_id,
      to: email,
      reply_to_id: @reply_to_id,
      personalisation: {
          project_ref_number: project_reference_num,
          project_title: project_title,
          payment_amount: payment_amount
      }
    )

  end

  # Send project update and payment request emails following an arrears journey
  # @param [String] email
  # @param [String] project_title
  # @param [String] project_reference_number
  # @param [String] payment_amount as a currency string
  # @param [String] template_id GOV.UK guid for reqd template
  def arrears_payment_progress_submisson_confirmation(email, project_title, project_reference_num,
    payment_amount, template_id)

    logger.info "Sent arrears_payment_progress_submisson_confirmation " \
      "email to: #{email}"

    template_mail(
      template_id,
      to: email,
      reply_to_id: @reply_to_id,
      personalisation: {
          project_ref_number: project_reference_num,
          project_title: project_title,
          payment_amount: payment_amount
      }
    )

  end

  # Send project update emails following an arrears journey
  # @param [String] email
  # @param [String] project_title
  # @param [String] project_reference_number
  # @param [String] template_id GOV.UK guid for reqd template
  def arrears_project_update_submisson_confirmation(email, project_title, project_reference_num,
    template_id)

    logger.info "Sent arrears_project_update_submisson_confirmation " \
      "email to: #{email}"

    template_mail(
      template_id,
      to: email,
      reply_to_id: @reply_to_id,
      personalisation: {
          project_ref_number: project_reference_num,
          project_title: project_title
      }
    )

  end

end
