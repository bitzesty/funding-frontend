# Orchestrates languages for PEF emails.
# Sits between controllers and NotifyMailer.

module Mailers::PefMailerHelper

  include Mailers::CommonMailerHelper

  def project_enquiry_submission_confirmation(email, reference)
    
    deliver_project_enquiry_submission_confirmation(
      email,
      reference,
      '34ec207b-e8d1-46be-87ee-2eca4b665cbc'
    ) if send_english_mails?

    deliver_project_enquiry_submission_confirmation(
      email,
      reference,
      '7738f808-ad66-40a4-8f64-bacffdb70972'
    ) if send_welsh_mails?

    deliver_project_enquiry_submission_confirmation(
      email,
      reference,
      'c4675b50-6cbb-4b56-a24f-6a1340f5d530'
    ) if send_bilingual_mails?

    log_mails_sent(__method__.to_s)

  end

  def deliver_project_enquiry_submission_confirmation(email, 
    reference, template_id)

    NotifyMailer.project_enquiry_submission_confirmation(
      email,
      reference,
      template_id
    ).deliver_later()

  end
  
end
