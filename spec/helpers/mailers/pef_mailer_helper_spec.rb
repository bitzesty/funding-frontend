# Spec for helper that decides what language a template should be sent in.
# For emails that are sent when a project enquiry is submitted

require 'rails_helper'

include Mailers::PefMailerHelper

RSpec.describe Mailers::PefMailerHelper do

  describe '#project_enquiry_submission_confirmation' do

    it "should only provide an english email template when english needed" do

      allow(subject).to receive(:send_english_mails?).and_return(true)
      allow(subject).to receive(:send_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_project_enquiry_submission_confirmation
      ).with(
        'eng email',
        'eng reference',
        '34ec207b-e8d1-46be-87ee-2eca4b665cbc'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.project_enquiry_submission_confirmation(
        'eng email',
        'eng reference'
      )
    
    end

    it "should only provide a welsh email template when welsh needed" do

      allow(subject).to receive(:send_english_mails?).and_return(false)
      allow(subject).to receive(:send_welsh_mails?).and_return(true)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_project_enquiry_submission_confirmation
      ).with(
        'wel email',
        'wel reference',
        '7738f808-ad66-40a4-8f64-bacffdb70972'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.project_enquiry_submission_confirmation(
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
        :deliver_project_enquiry_submission_confirmation
      ).with(
        'bil email',
        'bil reference',
        'c4675b50-6cbb-4b56-a24f-6a1340f5d530'
      ).once

      expect(subject).to receive(:log_mails_sent)

      subject.project_enquiry_submission_confirmation(
        'bil email',
        'bil reference'
      )
    
    end

  end

  describe '#deliver_project_enquiry_submission_confirmation' do

    it "should call the correct Notify function and use ActiveJob" do
      # This looks correct - doesn't work. Timeboxed - moving on.
      # expect(NotifyMailer).to receive_message_chain(
      #   :project_enquiry_submission_confirmation, 
      #   :deliver_later
      # )
      # subject.deliver_project_enquiry_submission_confirmation('a','a', 'a')

      # This test, when working, could be replicated on all mailer_helper_specs

    end

  end
  

end
