# Spec for helper that decides what language a template should be sent in.
# For emails that are sent when a 3-10k application (gp_project) is submitted

require 'rails_helper'

include Mailers::GpProjectMailerHelper

RSpec.describe Mailers::GpProjectMailerHelper do

  describe '#send_project_submission_confirmation' do

    it "should only provide an english email template when english needed" do

      allow(subject).to receive(:send_project_english_mails?).and_return(true)
      allow(subject).to receive(:send_project_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_project_bilingual_mails?).and_return(false)
      allow(subject).to receive(:set_user_instance).once
      expect(subject).to receive(
        :deliver_project_submission_confirmation
      ).with(
        'eng email',
        'eng reference',
        '071cfcda-ebd4-4eba-8602-338b12edc4f9'
        ).once

      expect(subject).to receive(:log_project_mails_sent)

      subject.send_project_submission_confirmation(
        15,
        'eng email',
        'eng reference'
      )
    
    end

    it "should only provide a welsh email template when welsh needed" do

      allow(subject).to receive(:send_project_english_mails?).and_return(false)
      allow(subject).to receive(:send_project_welsh_mails?).and_return(true)
      allow(subject).to receive(:send_project_bilingual_mails?).and_return(false)
      allow(subject).to receive(:set_user_instance).once
      expect(subject).to receive(
        :deliver_project_submission_confirmation
      ).with(
        'wel email',
        'wel reference',
        '08f53e02-da3a-4bb2-8cab-325d411588b2'
        ).once

      expect(subject).to receive(:log_project_mails_sent)

      subject.send_project_submission_confirmation(
        16,
        'wel email',
        'wel reference'
      )
    
    end

    it "should only provide an bilingual email template when " \
      "bilingual needed" do

      allow(subject).to receive(:send_project_english_mails?).and_return(false)
      allow(subject).to receive(:send_project_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_project_bilingual_mails?).and_return(true)
      allow(subject).to receive(:set_user_instance).once
      expect(subject).to receive(
        :deliver_project_submission_confirmation
      ).with(
        'bil email',
        'bil reference',
        'ee485b3c-5f06-4211-9cb6-bb342b3e0769'
      ).once

      expect(subject).to receive(:log_project_mails_sent)

      subject.send_project_submission_confirmation(
        17,
        'bil email',
        'bil reference'
      )
    
    end

  end

end
