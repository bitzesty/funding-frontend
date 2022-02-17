# Helper containing common code used by other mailer helpers.
module Mailers::CommonMailerHelper

  def log_mails_sent(function_name)

    logger.info("#{function_name} called for " \
      "user id #{user_id} " \
        "English mail sent? : #{send_english_mails?} " \
          "Welsh mail sent? : #{send_welsh_mails?} " \
            "Bilingual mail sent? : #{send_bilingual_mails?}" \
    )

  end

  # Issues mocking current_user owing to Devise.  
  # These methods enable easy mocking
  def send_english_mails?
    current_user.send_english_mails?
  end

  def send_welsh_mails?
    current_user.send_welsh_mails?
  end

  def send_bilingual_mails?
    current_user.send_bilingual_mails?
  end

  def user_id
    current_user.id
  end

end
