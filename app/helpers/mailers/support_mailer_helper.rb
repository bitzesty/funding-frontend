# Orchestrates languages for Support emails.
# Sits between controllers and NotifyMailer.

module Mailers::SupportMailerHelper

  include Mailers::CommonMailerHelper

  def mail_question_or_feedback(message, name, email)
    
    deliver_question_or_feedback(
      message,
      name,
      email,
      '7beca953-0a9d-466e-9845-649b86270f14'
    ) if send_english_mails?

    deliver_question_or_feedback(
      message,
      name,
      email,
      '0bfdb84b-c0d8-46de-b21b-2b452d504df6'
    ) if send_welsh_mails?

    deliver_question_or_feedback(
      message,
      name,
      email,
      'f969124b-be35-4210-ad55-366ebd60dfa9'
    ) if send_bilingual_mails?

    log_mails_sent(__method__.to_s)

  end

  def deliver_question_or_feedback(message, name, email, template_id)

    NotifyMailer.question_or_feedback(
      message,
      name,
      email,
      template_id
    ).deliver_later()

  end

  def mail_report_a_problem(message, name, email)
    
    deliver_report_a_problem(
      message,
      name,
      email,
      'f698e225-c007-4f50-9766-43773790a5c4'
    ) if send_english_mails?

    deliver_report_a_problem(
      message,
      name,
      email,
      '8417933f-ce9a-4012-8e76-f78dd365bf0d'
    ) if send_welsh_mails?

    deliver_report_a_problem(
      message,
      name,
      email,
      '8a3996c0-d370-4e59-9260-3d0e89a2ca12'
    ) if send_bilingual_mails?

    log_mails_sent(__method__.to_s)

  end

  def deliver_report_a_problem(message, name, email, template_id)

    NotifyMailer.report_a_problem(
      message,
      name,
      email,
      template_id
    ).deliver_later()

  end
  
end
