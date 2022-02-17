# Spec for helper that decides what language a template should be sent in.
# For emails that are sent when a project enquiry is submitted

require 'rails_helper'

include Mailers::PaymentMailerHelper

RSpec.describe Mailers::PaymentMailerHelper do

  describe '#payment_request_submission_confirmation' do

    it "should only provide an english email template when english needed" do

      allow(subject).to receive(:send_english_mails?).and_return(true)
      allow(subject).to receive(:send_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_payment_request_submission_confirmation
      ).with(
        'eng email',
        'eng reference',
        'eng investment manager',
        'eng investment manager email',
        'e35a0532-8b51-4447-bc6d-d39f705bd24c'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.payment_request_submission_confirmation(
        'eng email',
        'eng reference',
        'eng investment manager',
        'eng investment manager email'
      )
    
    end

    it "should only provide a welsh email template when welsh needed" do

      allow(subject).to receive(:send_english_mails?).and_return(false)
      allow(subject).to receive(:send_welsh_mails?).and_return(true)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_payment_request_submission_confirmation
      ).with(
        'wel email',
        'wel reference',
        'wel investment manager',
        'wel investment manager email',
        'ba6ed95d-f89e-4211-8663-e5bc1153b81e'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.payment_request_submission_confirmation(
        'wel email',
        'wel reference',
        'wel investment manager',
        'wel investment manager email'
      )
    
    end

    it "should only provide an bilingual email template when " \
      "bilingual needed" do

      allow(subject).to receive(:send_english_mails?).and_return(false)
      allow(subject).to receive(:send_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_bilingual_mails?).and_return(true)
      expect(subject).to receive(
        :deliver_payment_request_submission_confirmation
      ).with(
        'bil email',
        'bil reference',
        'bil investment manager',
        'bil investment manager email',
        '8fc10e9e-7f8d-47b7-8b23-c9d5e4c7c9b0'
      ).once

      expect(subject).to receive(:log_mails_sent)

      subject.payment_request_submission_confirmation(
        'bil email',
        'bil reference',
        'bil investment manager',
        'bil investment manager email'
      )
    
    end

  end

end
