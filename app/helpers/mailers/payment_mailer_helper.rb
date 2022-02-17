# Orchestrates languages for payment emails.
# Sits between controllers and NotifyMailer.

module Mailers::PaymentMailerHelper

  include Mailers::CommonMailerHelper

  def payment_request_submission_confirmation(email, reference,
    investment_manager_name, investment_manager_email)
    
    deliver_payment_request_submission_confirmation(
      email,
      reference,
      investment_manager_name,
      investment_manager_email,
      'e35a0532-8b51-4447-bc6d-d39f705bd24c'
    ) if send_english_mails?

    deliver_payment_request_submission_confirmation(
      email,
      reference,
      investment_manager_name,
      investment_manager_email,
      'ba6ed95d-f89e-4211-8663-e5bc1153b81e'
    ) if send_welsh_mails?

    deliver_payment_request_submission_confirmation(
      email,
      reference,
      investment_manager_name,
      investment_manager_email,
      '8fc10e9e-7f8d-47b7-8b23-c9d5e4c7c9b0'
    ) if send_bilingual_mails?

    log_mails_sent(__method__.to_s)

  end

  def deliver_payment_request_submission_confirmation(email, 
    reference, investment_manager_name, investment_manager_email,
      template_id)

    NotifyMailer.payment_request_submission_confirmation(
      email,
      reference,
      investment_manager_name,
      investment_manager_email,
      template_id
    ).deliver_later()

  end
  
end
