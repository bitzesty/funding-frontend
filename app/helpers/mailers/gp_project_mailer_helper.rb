# Orchestrates languages for gp_project (3-10k) emails.
# Sits between controllers and NotifyMailer.

module Mailers::GpProjectMailerHelper

  def send_project_submission_confirmation(project_user_id, email, reference)
    
    set_user_instance(project_user_id)

    deliver_project_submission_confirmation(
      email,
      reference,
      '071cfcda-ebd4-4eba-8602-338b12edc4f9'
    ) if send_project_english_mails?

    deliver_project_submission_confirmation(
      email,
      reference,
      '08f53e02-da3a-4bb2-8cab-325d411588b2'
    ) if send_project_welsh_mails?

    deliver_project_submission_confirmation(
      email,
      reference,
      'ee485b3c-5f06-4211-9cb6-bb342b3e0769'
    ) if send_project_bilingual_mails?

    log_project_mails_sent(__method__.to_s, project_user_id)

  end

  def deliver_project_submission_confirmation(email, 
    reference, template_id)

    NotifyMailer.project_submission_confirmation(
      email,
      reference,
      template_id
    ).deliver_later()

  end

  private

  def log_project_mails_sent(function_name, project_user_id)

    logger.info("#{function_name} called for " \
      "user id #{project_user_id} " \
        "English mail sent? : #{send_project_english_mails?} " \
          "Welsh mail sent? : #{send_project_welsh_mails?} " \
            "Bilingual mail sent? : #{send_project_bilingual_mails?}" \
    )

  end

  # current_user unavailable for the 3-10k application journey.
  # Instead, get the user from the database.
  # This code still works for journeys with applications > 10k.
  def set_user_instance(user_id)
    @project_user = User.find(user_id)
  end

  # These methods enable easy mocking
  def send_project_english_mails?
    @project_user.send_english_mails?
  end

  def send_project_welsh_mails?
    @project_user.send_welsh_mails?
  end

  def send_project_bilingual_mails?
    @project_user.send_bilingual_mails?
  end

end
