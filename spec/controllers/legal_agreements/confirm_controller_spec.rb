require 'rails_helper'

RSpec.describe FundingApplication::LegalAgreements::ConfirmController do
 
  describe '#trigger_legal_signatory_emails' do
    login_user

    let(:legal_sig_one) {
      create(
        :legal_signatory,
        id: '1',
        name: 'Joe Bloggs',
        email_address: 'joe@bloggs.com',
        phone_number: '07000000000'
      )
    }

    let(:legal_sig_two) {
      create(
        :legal_signatory,
        id: '2',
        name: 'John Dear',
        email_address: 'john@dear.com',
        phone_number: '07000000000'
      )
    }

    before do

      allow_any_instance_of(FundingApplicationHelper).to receive(:is_applicant_legal_signatory?).and_return(false)
      allow_any_instance_of(LegalAgreementsHelper).to receive(:encode_legal_signatory_id).and_return("1234567abcdefg")

      subject.current_user.organisations.first.update(
        name: 'Test Organisation',
        line1: '10 Downing Street',
        line2: 'Westminster',
        townCity: 'London',
        county: 'London',
        postcode: 'SW1A 2AA',
        org_type: 1
      )

      subject.current_user.organisations.first.legal_signatories.append(legal_sig_one)
      subject.current_user.organisations.first.legal_signatories.append(legal_sig_two)
      
    end

    let(:funding_application) {
      create(
        :funding_application,
        id: 'id',
        organisation_id: subject.current_user.organisations.first.id,
        project: nil
      )
    }

    it "it calls trigger_legal_signatory_emails and where both legal" \
     "signatories are not the applicant emails are sent to both the legal sigs and support" do

      # Generate magic link for emails
      expect(subject).to receive(:build_agreement_link).twice.and_return("http://test_legal_sig_url.com")

      # Send email to legal sig 1 and support 
      expect(subject).to receive(:send_legal_signatory_email).with("joe@bloggs.com", funding_application, "http://test_legal_sig_url.com", "." )
      expect(subject).to receive(:send_legal_signatory_email).with("no_reply@test.com", funding_application, "http://test_legal_sig_url.com", " FAO - joe@bloggs.com" )

      # Send email to legal sig 2 and support 
      expect(subject).to receive(:send_legal_signatory_email).with("john@dear.com", funding_application, "http://test_legal_sig_url.com", "." )
      expect(subject).to receive(:send_legal_signatory_email).with("no_reply@test.com", funding_application, "http://test_legal_sig_url.com", " FAO - john@dear.com" )

      subject.trigger_legal_signatory_emails(funding_application, subject.current_user)
    end
  end
end
