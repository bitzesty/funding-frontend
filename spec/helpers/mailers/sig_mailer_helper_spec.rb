require 'rails_helper'

include Mailers::SigMailerHelper

RSpec.describe Mailers::SigMailerHelper do

  describe '#send_mail_with_signatory_link' do

    it "should only provide an english email template when english needed" do

      allow(subject).to receive(:send_english_mails?).and_return(true)
      allow(subject).to receive(:send_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_email_with_signatory_link
      ).with(
        'eng email',
        'eng funding application id',
        'eng agreement_link',
        'eng project_title',
        'eng project_reference_number',
        'eng organisation_name', 
        'eng fao_email',
        '9ba83d4a-e445-4c12-9f03-545bcbca4878'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.send_mail_with_signatory_link(
        'eng email',
        'eng funding application id',
        'eng agreement_link',
        'eng project_title',
        'eng project_reference_number',
        'eng organisation_name', 
        'eng fao_email'
      )
    
    end

    it "should only provide a welsh email template when welsh needed" do

      allow(subject).to receive(:send_english_mails?).and_return(false)
      allow(subject).to receive(:send_welsh_mails?).and_return(true)
      allow(subject).to receive(:send_bilingual_mails?).and_return(false)
      expect(subject).to receive(
        :deliver_email_with_signatory_link
      ).with(
        'wel email',
        'wel funding application id',
        'wel agreement_link',
        'wel project_title',
        'wel project_reference_number',
        'wel organisation_name', 
        'wel fao_email',
        'ba8de19e-eb15-46e9-a415-71b5167fb170'
        ).once

      expect(subject).to receive(:log_mails_sent)

      subject.send_mail_with_signatory_link(
        'wel email',
        'wel funding application id',
        'wel agreement_link',
        'wel project_title',
        'wel project_reference_number',
        'wel organisation_name', 
        'wel fao_email'
      )
    
    end

    it "should only provide an bilingual email template when " \
      "bilingual needed" do

      allow(subject).to receive(:send_english_mails?).and_return(false)
      allow(subject).to receive(:send_welsh_mails?).and_return(false)
      allow(subject).to receive(:send_bilingual_mails?).and_return(true)
      expect(subject).to receive(
        :deliver_email_with_signatory_link
      ).with(
        'bil email',
        'bil funding application id',
        'bil agreement_link',
        'bil project_title',
        'bil project_reference_number',
        'bil organisation_name', 
        'bil fao_email',
        '3290db41-b688-4ea1-b48d-c1258adbd30c'
      ).once

      expect(subject).to receive(:log_mails_sent)

      subject.send_mail_with_signatory_link(
        'bil email',
        'bil funding application id',
        'bil agreement_link',
        'bil project_title',
        'bil project_reference_number',
        'bil organisation_name', 
        'bil fao_email'
      )
    
    end

  end

end
