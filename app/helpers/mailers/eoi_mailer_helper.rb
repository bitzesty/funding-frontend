# Orchestrates languages for EOI emails.
# Sits between controllers and NotifyMailer.

module Mailers::EoiMailerHelper

  include Mailers::CommonMailerHelper

  def expression_of_interest_submission_confirmation(email, reference)
    
    deliver_expression_of_interest_submission_confirmation(
      email,
      reference,
      '76cba30c-e91b-4fae-bffc-78ee13179b9c'
    ) if send_english_mails?

    deliver_expression_of_interest_submission_confirmation(
      email,
      reference,
      '4f380675-b5e3-4281-8513-91922e0dc68f'
    ) if send_welsh_mails?

    deliver_expression_of_interest_submission_confirmation(
        email,
        reference,
        'b374401f-a5f2-4f16-8ebc-9a243fe0168d'
    ) if send_bilingual_mails?

    log_mails_sent(__method__.to_s)

  end

  def deliver_expression_of_interest_submission_confirmation(email, 
    reference, template_id)

    NotifyMailer.expression_of_interest_submission_confirmation(
      email,
      reference,
      template_id
    ).deliver_later()

  end
  
end
