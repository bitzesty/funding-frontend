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
      "send a copy of the bilingual account registration mail to support" do

      # mock the devise_confirmation_url function
      allow(subject).to receive(:devise_confirmation_url).with(mock_record, 
        {:confirmation_token=>"token"})

      # check that when confirmation_instructions_copy is called that
      # template_mail is called with the expected parameters
      expect(subject).to receive(:template_mail).with(
        "cccbf9f4-a633-453e-9b32-24f1c86879ec", 
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

  describe '#email_with_signatory_link'  do

      recipient_email_address = "user@email.com"
      funding_application_id = "NH-TEST-123"
      agreement_link = "http://agreement_link.com"
      project_title = "Project Title"
      project_reference_number = "123456"
      organisation_name = "TestOrg"
      template_id = "a template id"


    it "should call the email_with_signatory_link method which " \
      "send a legal agreements magic link email to user" do

      # check that when email_with_signatory_link is called that
      # template_mail is called with the expected parameters
      expect(subject).to receive(:template_mail).with(
        template_id, 
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
      subject.email_with_signatory_link(
        recipient_email_address, 
        funding_application_id, 
        agreement_link, 
        project_title, 
        project_reference_number, 
        organisation_name,
        ".",
        template_id
      )

    end

  end

  describe '#project_enquiry_submission_confirmation'  do

    it "forwards the correct information to Notify" do

      subject.instance_eval {@reply_to_id = 'a_reply_email'}

      expect(subject).to receive(:template_mail).with(
        "a_template_id", 
        {
          :personalisation=>{
            :pa_project_enquiry_reference=> 'a_reference'
          }, 
          :reply_to_id=>"a_reply_email", 
          :to=> 'pef_applicant_email'
        }
      )

      # Call the Notify class function that we are testing
      subject.project_enquiry_submission_confirmation(
        'pef_applicant_email', 
        'a_reference', 
        'a_template_id'
      )

    end

  end

  describe '#expression_of_interest_submission_confirmation'  do

    it "forwards the correct information to Notify" do

      subject.instance_eval {@reply_to_id = 'a_reply_email'}

      expect(subject).to receive(:template_mail).with(
        "an_eoi_template_id", 
        {
          :personalisation=>{
            :pa_expression_of_interest_reference=> 'an_eoi_reference'
          }, 
          :reply_to_id=>"a_reply_email", 
          :to=> 'eoi_applicant_email'
        }
      )

      # Call the Notify class function that we are testing
      subject.expression_of_interest_submission_confirmation(
        'eoi_applicant_email', 
        'an_eoi_reference', 
        'an_eoi_template_id'
      )

    end

  end
  
  describe '#pts_submission_confirmation'  do

    it "forwards the correct information to Notify" do

      subject.instance_eval {@reply_to_id = 'a_reply_email'}

      expect(subject).to receive(:template_mail).with(
        "a_pts_template_id", 
        {
          :personalisation=>{
            :project_reference_number=> 'a_large_project_reference'
          }, 
          :reply_to_id=>"a_reply_email", 
          :to=> 'pts_applicant_email'
        }
      )

      # Call the Notify class function that we are testing
      subject.pts_submission_confirmation(
        'pts_applicant_email', 
        'a_large_project_reference', 
        'a_pts_template_id'
      )

    end

  end

  describe '#project_submission_confirmation'  do

    it "forwards the correct information to Notify" do

      subject.instance_eval {@reply_to_id = 'a_reply_email'}

      expect(subject).to receive(:template_mail).with(
        "a_project_submission_confirmation_template_id", 
        {
          :personalisation=>{
            :project_reference_number=> 'a_project_reference'
          }, 
          :reply_to_id=>"a_reply_email", 
          :to=> 'project_applicant_email'
        }
      )

      # Call the Notify class function that we are testing
      subject.project_submission_confirmation(
        'project_applicant_email', 
        'a_project_reference', 
        'a_project_submission_confirmation_template_id'
      )

    end

  end

  describe '#payment_request_submission_confirmation'  do

    it "forwards the correct information to Notify" do

      subject.instance_eval {@reply_to_id = 'a_reply_email'}

      expect(subject).to receive(:template_mail).with(
        "a_payment_request_submission_confirmation_template_id", 
        {
          :personalisation=>{
            :project_reference_number=> 'a_project_reference',
            :investment_manager_name=> 'investment manager name',
            :investment_manager_email=> 'investment manager email'
          }, 
          :reply_to_id=>"a_reply_email", 
          :to=> 'project_applicant_email'
        }
      )

      # Call the Notify class function that we are testing
      subject.payment_request_submission_confirmation(
        'project_applicant_email',
        'a_project_reference',
        'investment manager name',
        'investment manager email',
        'a_payment_request_submission_confirmation_template_id'
      )

    end

  end

  describe '#question_or_feedback'  do

    it "forwards the correct information to Notify" do

      subject.instance_eval {@reply_to_id = 'a_reply_email'}

      expect(subject).to receive(:template_mail).with(
        "a_question_or_feedback_template_id", 
        {
          :personalisation=>{
            :message_body=> 'a message',
            :user_email_address=> 'an email',
            :name=> 'a name'
          }, 
          :reply_to_id=>"a_reply_email", 
          :to=> 'test@test.com'
        }
      )

      # Call the Notify class function that we are testing
      subject.question_or_feedback(
        'a message',
        'a name',
        'an email',
        'a_question_or_feedback_template_id'
      )

    end

  end

  describe '#report_a_problem'  do

    it "forwards the correct information to Notify" do

      subject.instance_eval {@reply_to_id = 'a_reply_email'}

      expect(subject).to receive(:template_mail).with(
        "a_report_a_problem_template_id", 
        {
          :personalisation=>{
            :message_body=> 'a message',
            :user_email_address=> 'an email',
            :name=> 'a name'
          }, 
          :reply_to_id=>"a_reply_email", 
          :to=> 'test@test.com'
        }
      )

      # Call the Notify class function that we are testing
      subject.report_a_problem(
        'a message',
        'a name',
        'an email',
        'a_report_a_problem_template_id'
      )

    end

  end

end
