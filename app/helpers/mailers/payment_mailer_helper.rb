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



  def dev_to_100k_payment_request_confirmation(email, reference, payment_amount, ffty_prcnt_prjct_cst)
    deliver_dev_to_100k_payment_request_confirmation(
      email,
      reference,
      payment_amount, 
      ffty_prcnt_prjct_cst,
      '86dea493-d5b6-4534-a06f-a0a94b3e807c'
    ) if send_english_mails?

    deliver_dev_to_100k_payment_request_confirmation(
      email,
      reference,
      payment_amount, 
      ffty_prcnt_prjct_cst,
      '1000d122-6b4a-4f5c-88b6-e26f8449604d'
    ) if send_welsh_mails?

    deliver_dev_to_100k_payment_request_confirmation(
      email,
      reference,
      payment_amount, 
      ffty_prcnt_prjct_cst,
      'e74620c1-65c0-4af4-b3d8-7bbe90e6df8a'
    ) if send_bilingual_mails?

    log_mails_sent(__method__.to_s)
  end

  private

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

  def deliver_dev_to_100k_payment_request_confirmation(
    email, 
    reference, 
    payment_amount, 
    ffty_prcnt_prjct_cst,
    template_id
  )

    NotifyMailer.dev_to_100k_payment_request_confirmation(
      email, 
      reference, 
      payment_amount, 
      ffty_prcnt_prjct_cst,
      template_id
    ).deliver_later()

  end
  
end
