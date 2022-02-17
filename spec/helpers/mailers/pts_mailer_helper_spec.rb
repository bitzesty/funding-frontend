# Helper that decides what language a template should be sent in.
# For emails that are sent upon a permission to start submission

require 'rails_helper'

include Mailers::PtsMailerHelper

RSpec.describe Mailers::PtsMailerHelper do

  describe '#send_pts_submission_confirmation' do

    it "should only provide an english email template when english needed" do

      allow(subject).to receive(:send_english_mails?).and_return(true)
      allow(subject).to receive(:send_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_pts_submission_confirmation
      ).with(
        'eng email',
        'eng reference',
        '24833676-a335-4e88-9fff-2470b4fe0b95'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.send_pts_submission_confirmation(
        'eng email',
        'eng reference'
      )
    
    end

    it "should only provide a welsh email template when welsh needed" do

      allow(subject).to receive(:send_english_mails?).and_return(false)
      allow(subject).to receive(:send_welsh_mails?).and_return(true)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_pts_submission_confirmation
      ).with(
        'wel email',
        'wel reference',
        'ed6866bd-966c-4c0c-b1d5-384563fe1ba0'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.send_pts_submission_confirmation(
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
        :deliver_pts_submission_confirmation
      ).with(
        'bil email',
        'bil reference',
        '501541dc-e837-48c6-a744-65a326f3180e'
      ).once

      expect(subject).to receive(:log_mails_sent)

      subject.send_pts_submission_confirmation(
        'bil email',
        'bil reference'
      )
    
    end

  end

end
