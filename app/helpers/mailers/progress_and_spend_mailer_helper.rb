# Orchestrates languages for PEF emails.
# Sits between controllers and NotifyMailer.

module Mailers::ProgressAndSpendMailerHelper

  include Mailers::CommonMailerHelper

  # Uses completed_arrears_journey to see what has been submitted.
  #
  # @param [CompletedArrearsJourney] completed_arrears_journey
  # @param [String] project_title
  # @param [String] project_reference_number
  # @param [String] payment_amount as a currency string
  def send_confirmation_email(completed_arrears_journey, project_title,
    project_reference_num, payment_amount)

    progress_mail = \
      completed_arrears_journey.progress_update_id.present?

    payment_mail = \
      completed_arrears_journey.payment_request_id.present?

    combined_mail = \
      progress_mail && payment_mail

    email = 
      completed_arrears_journey.funding_application.\
        organisation.users.first.email

    if combined_mail
      
      send_combined_email(
        email,
        project_title,
        project_reference_num,
        payment_amount
      )

    elsif progress_mail

      send_progress_email(
        email,
        project_title,
        project_reference_num
      )

    elsif payment_mail

      send_payment_mail(
        email,
        project_title,
        project_reference_num,
        payment_amount
      )

    end
  
  end

  # A progress update and payment request was submitted, send mail for that.
  # Also chooses the appropriate template language.
  #
  # @param [String] email
  # @param [String] project_title
  # @param [String] project_reference_number
  # @param [String] payment_amount as a currency string
  def send_combined_email(email, project_title, project_reference_num,
    payment_amount)

    deliver_arrears_payment_progress_submisson_confirmation(
      email,
      project_title,
      project_reference_num,
      payment_amount,
      '556c8ffc-26b5-4e90-9abd-53b7eb9e8c33'
    ) if send_english_mails?

    deliver_arrears_payment_progress_submisson_confirmation(
      email,
      project_title,
      project_reference_num,
      payment_amount,
      '4f3cc832-5d5b-4eba-9be3-befc3b981bae'
    ) if send_welsh_mails?

    deliver_arrears_payment_progress_submisson_confirmation(
      email,
      project_title,
      project_reference_num,
      payment_amount,
      '4688d6ae-1d90-4710-8f06-f906d52a4ac1'
    ) if send_bilingual_mails?

    log_mails_sent(__method__.to_s)

  end

  # Only a Progress update was submitted, send a project update mail for that.
  # Also chooses the appropriate template language.
  #
  # @param [CompletedArrearsJourney] completed_arrears_journey
  #
  # @param [String] email
  # @param [String] project_title
  # @param [String] project_reference_number
  def send_progress_email(email, project_title, project_reference_num)

    deliver_arrears_project_update_submisson_confirmation(
      email,
      project_title,
      project_reference_num,
      'f600787a-e3d8-4bbe-b51c-92112a12ab85'
    ) if send_english_mails?

    deliver_arrears_project_update_submisson_confirmation(
      email,
      project_title,
      project_reference_num,
      'fde18f78-2523-4235-b3bf-c314e842073b'
    ) if send_welsh_mails?

    deliver_arrears_project_update_submisson_confirmation(
      email,
      project_title,
      project_reference_num,
      'f60f1fb5-2bf7-4310-9d5d-34faa0e67450'
    ) if send_bilingual_mails?

    log_mails_sent(__method__.to_s)

  end

  # Only a Payment request was submitted, send a mail for that.
  # Also chooses the appropriate template language.
  #
  # @param [String] email
  # @param [String] project_title
  # @param [String] project_reference_number
  # @param [String] payment_amount as a currency string
  def send_payment_mail(email, project_title, project_reference_num,
    payment_amount)

    deliver_arrears_payment_request_submisson_confirmation(
      email,
      project_title,
      project_reference_num,
      payment_amount,
      'c48f63eb-1c26-4727-bdf0-52de62e52cf4'
    ) if send_english_mails?

    deliver_arrears_payment_request_submisson_confirmation(
      email,
      project_title,
      project_reference_num,
      payment_amount,
      '24a11c70-c372-48e8-83f5-85cbc3471e31'
    ) if send_welsh_mails?

    deliver_arrears_payment_request_submisson_confirmation(
      email,
      project_title,
      project_reference_num,
      payment_amount,
      '30be9fc5-65f0-4cfc-bd08-8434187360f5'
    ) if send_bilingual_mails?

    log_mails_sent(__method__.to_s)

  end

  private

  # Uses NotifyMailer to send the arrears payment request emails to Notify
  # @param [String] email
  # @param [String] project_title
  # @param [String] project_reference_number
  # @param [String] payment_amount as a currency string
  # @param [String] template_id GOV.UK guid for reqd template
  def deliver_arrears_payment_request_submisson_confirmation(email,
    project_title, project_reference_num, payment_amount, template_id)

    NotifyMailer.arrears_payment_request_submisson_confirmation(
      email,
      project_title,
      project_reference_num,
      payment_amount,
      template_id
    ).deliver_later()

  end

  # Uses NotifyMailer to send project update and payment request emails
  # to Notify
  # @param [String] email
  # @param [String] project_title
  # @param [String] project_reference_number
  # @param [String] payment_amount as a currency string
  # @param [String] template_id GOV.UK guid for reqd template
  def deliver_arrears_payment_progress_submisson_confirmation(email,
    project_title, project_reference_num, payment_amount, template_id)

    NotifyMailer.arrears_payment_progress_submisson_confirmation(
      email,
      project_title,
      project_reference_num,
      payment_amount,
      template_id
    ).deliver_later()

  end

  # Uses NotifyMailer to send project update emails to Notify
  # @param [String] email
  # @param [String] project_title
  # @param [String] project_reference_number
  # @param [String] template_id GOV.UK guid for reqd template
  def deliver_arrears_project_update_submisson_confirmation(email,
    project_title, project_reference_num, template_id)

    NotifyMailer.arrears_project_update_submisson_confirmation(
      email,
      project_title,
      project_reference_num,
      template_id
    ).deliver_later()

  end
  
end
