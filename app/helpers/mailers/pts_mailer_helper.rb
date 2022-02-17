# Orchestrates languages for permission to start emails.
# Sits between controllers and NotifyMailer.

module Mailers::PtsMailerHelper

  include Mailers::CommonMailerHelper

  def send_pts_submission_confirmation(email, reference)
    
    deliver_pts_submission_confirmation(
      email,
      reference,
      '24833676-a335-4e88-9fff-2470b4fe0b95'
    ) if send_english_mails?

    deliver_pts_submission_confirmation(
      email,
      reference,
      'ed6866bd-966c-4c0c-b1d5-384563fe1ba0'
    ) if send_welsh_mails?

    deliver_pts_submission_confirmation(
      email,
      reference,
      '501541dc-e837-48c6-a744-65a326f3180e'
    ) if send_bilingual_mails?

    log_mails_sent(__method__.to_s)

  end

  def deliver_pts_submission_confirmation(email, 
    reference, template_id)

    NotifyMailer.pts_submission_confirmation(
      email,
      reference,
      template_id
    ).deliver_later()

  end
  
end
