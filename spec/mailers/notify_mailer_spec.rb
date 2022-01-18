require "rails_helper"

class MockRecord

  attr_accessor :confirmation_token
  attr_accessor :email

end

RSpec.describe NotifyMailer do
  
  mock_record = MockRecord.new
  mock_record.confirmation_token = 'token'
  mock_record.email = 'test@test.com'

  describe '#confirmation_instructions_copy'  do

    it "should call the confirmation_instructions_copy method which " \
      "send a copy of the account registration mail to support" do

      # mock the devise_confirmation_url function
      allow(subject).to receive(:devise_confirmation_url).with(mock_record, {:confirmation_token=>"token"})

      # check that when confirmation_instructions_copy is called that
      # template_mail is called with the expected parameters
      expect(subject).to receive(:template_mail).with(
        "3eed6cd0-780a-4805-b5ef-79f170a1eb73", 
        {
          :personalisation=>{
            :confirmation_url=>nil,
            :fao_email=>" FAO - test@test.com"
          }, 
          :reply_to_id=>"reply@test.com", 
          :to=>"no_reply@test.com"
        }
      )

      # Call the Notify class function that we are testing
      subject.confirmation_instructions_copy(mock_record)

    end

  end

  describe '#legal_signatory_agreement_link'  do


      # initialise the notify mailer instance
      notify_mailer = NotifyMailer.new   

      recipient_email_address = "user@email.com"
      funding_application_id = "NH-TEST-123"
      agreement_link = "htttp://agreement_link.com"
      project_title = "Project Title"
      project_reference_number = "123456"
      organisation_name = "TestOrg"


    it "should call the legal_signatory_agreement_link method which " \
      "send a legal agreements magic link email to user" do

      # check that when legal_signatory_agreement_link is called that
      # template_mail is called with the expected parameters
      expect(subject).to receive(:template_mail).with(
        "9ba83d4a-e445-4c12-9f03-545bcbca4878", 
        {
          :personalisation=>{
            :funding_application_id=> funding_application_id,
            :agreement_link=> agreement_link,
            :project_title=> project_title,
            :project_reference_number=> project_reference_number,
            :organisation_name=> organisation_name,
            :fao_email=>"."
          }, 
          :reply_to_id=>"reply@test.com", 
          :to=> recipient_email_address
        }
      )

      # Call the Notify class function that we are testing
      subject.legal_signatory_agreement_link(
        recipient_email_address, 
        funding_application_id, 
        agreement_link, 
        project_title, 
        project_reference_number, 
        organisation_name,
        "."
      )

    end

  end

end
