# Spec for helper that decides what language a template should be sent in.
# For emails that are sent when an expression of interest is submitted

require 'rails_helper'

include Mailers::EoiMailerHelper

RSpec.describe Mailers::EoiMailerHelper do

  describe '#expression_of_interest_submission_confirmation' do

    it "should only provide an english email template when english needed" do

      allow(subject).to receive(:send_english_mails?).and_return(true)
      allow(subject).to receive(:send_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_expression_of_interest_submission_confirmation
      ).with(
        'eng email',
        'eng reference',
        '76cba30c-e91b-4fae-bffc-78ee13179b9c'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.expression_of_interest_submission_confirmation(
        'eng email',
        'eng reference'
      )
    
    end

    it "should only provide a welsh email template when welsh needed" do

      allow(subject).to receive(:send_english_mails?).and_return(false)
      allow(subject).to receive(:send_welsh_mails?).and_return(true)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_expression_of_interest_submission_confirmation
      ).with(
        'wel email',
        'wel reference',
        '4f380675-b5e3-4281-8513-91922e0dc68f'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.expression_of_interest_submission_confirmation(
        'wel email',
        'wel reference'
      )
    
    end

    it "should only provide an bilingual email template when " \
      "bilingual needed" do

      allow(subject).to receive(:send_english_mails?).and_return(false)
      allow(subject).to receive(:send_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_bilingual_mails?).and_return(true)
      expect(subject).to receive(
        :deliver_expression_of_interest_submission_confirmation
      ).with(
        'bil email',
        'bil reference',
        'b374401f-a5f2-4f16-8ebc-9a243fe0168d'
      ).once

      expect(subject).to receive(:log_mails_sent)

      subject.expression_of_interest_submission_confirmation(
        'bil email',
        'bil reference'
      )
    
    end

  end

end
