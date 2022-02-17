# Spec for helper that decides what language a template should be sent in.
# For emails that are sent when a project enquiry is submitted

require 'rails_helper'

include Mailers::SupportMailerHelper

RSpec.describe Mailers::SupportMailerHelper do

  describe '#mail_question_or_feedback' do

    it "should only provide an english email template when english needed" do

      allow(subject).to receive(:send_english_mails?).and_return(true)
      allow(subject).to receive(:send_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_question_or_feedback
      ).with(
        'eng msg',
        'eng name',
        'eng email',
        '7beca953-0a9d-466e-9845-649b86270f14'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.mail_question_or_feedback(
        'eng msg',
        'eng name',
        'eng email'
      )
    
    end

    it "should only provide a welsh email template when welsh needed" do

      allow(subject).to receive(:send_english_mails?).and_return(false)
      allow(subject).to receive(:send_welsh_mails?).and_return(true)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_question_or_feedback
      ).with(
        'wel msg',
        'wel name',
        'wel email',
        '0bfdb84b-c0d8-46de-b21b-2b452d504df6'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.mail_question_or_feedback(
        'wel msg',
        'wel name',
        'wel email'
      )
    
    end

    it "should only provide an bilingual email template when " \
      "bilingual needed" do

      allow(subject).to receive(:send_english_mails?).and_return(false)
      allow(subject).to receive(:send_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_bilingual_mails?).and_return(true)
      expect(subject).to receive(
        :deliver_question_or_feedback
      ).with(
        'bil msg',
        'bil name',
        'bil email',
        'f969124b-be35-4210-ad55-366ebd60dfa9'
      ).once

      expect(subject).to receive(:log_mails_sent)

      subject.mail_question_or_feedback(
        'bil msg',
        'bil name',
        'bil email'
      )
    
    end

  end

  describe '#mail_report_a_problem' do

    it "should only provide an english email template when english needed" do

      allow(subject).to receive(:send_english_mails?).and_return(true)
      allow(subject).to receive(:send_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_report_a_problem
      ).with(
        'eng msg',
        'eng name',
        'eng email',
        'f698e225-c007-4f50-9766-43773790a5c4'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.mail_report_a_problem(
        'eng msg',
        'eng name',
        'eng email'
      )
    
    end

    it "should only provide a welsh email template when welsh needed" do

      allow(subject).to receive(:send_english_mails?).and_return(false)
      allow(subject).to receive(:send_welsh_mails?).and_return(true)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_report_a_problem
      ).with(
        'wel msg',
        'wel name',
        'wel email',
        '8417933f-ce9a-4012-8e76-f78dd365bf0d'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.mail_report_a_problem(
        'wel msg',
        'wel name',
        'wel email'
      )
    
    end

    it "should only provide an bilingual email template when " \
      "bilingual needed" do

      allow(subject).to receive(:send_english_mails?).and_return(false)
      allow(subject).to receive(:send_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_bilingual_mails?).and_return(true)
      expect(subject).to receive(
        :deliver_report_a_problem
      ).with(
        'bil msg',
        'bil name',
        'bil email',
        '8a3996c0-d370-4e59-9260-3d0e89a2ca12'
      ).once

      expect(subject).to receive(:log_mails_sent)

      subject.mail_report_a_problem(
        'bil msg',
        'bil name',
        'bil email'
      )
    
    end

  end
  
end
