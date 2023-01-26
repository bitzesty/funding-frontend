# Orchestrates languages for project import mailer.
# Sits between controllers and NotifyMailer.

module Mailers::ImportMailerHelper

  include Mailers::CommonMailerHelper

  def send_email_to_support(
    support_mail_subject, 
    support_mail_body
  )

    deliver_send_email_to_support(
      support_mail_subject,
      support_mail_body,
      '1e92d866-3ff0-4e73-8288-3cdbb3a623b2'
    ) # if send_english_mails?

    # TODO: Include translation email templates


  end

  def deliver_send_email_to_support(
    support_mail_subject,
    support_mail_body, 
    template_id
  )

    NotifyMailer.send_email_to_support(
      support_mail_subject, 
      support_mail_body,
      template_id
    ).deliver_later
     
  end

end

