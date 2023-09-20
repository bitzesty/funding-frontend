require "rails_helper"

RSpec.describe LegalSignatory, type: :model do
  subject { build(:legal_signatory) }

  context "Validations" do
    it "validates the length of role" do
      subject.role = 'a' * 81
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:role]).to include("The role of the legal signatory must be fewer than 80 characters")
      
      subject.role = ''
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:role]).to include("Enter the role of a legal signatory")
      
      subject.role = 'Valid Role'
      expect(subject.valid?).to be_truthy
    end

    it "validates the length of name" do
      subject.name = 'a' * 81
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:name]).to include("The name of the legal signatory must be fewer than 80 characters")
      
      subject.name = ''
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:name]).to include("Enter the name of a legal signatory")
      
      subject.name = 'Valid Name'
      expect(subject.valid?).to be_truthy
    end
  end

  describe "Legal model" do

    let (:resource) {
      create(
        :legal_signatory,
        id: 1,
        email_address: 'a@f.com',
        role: 'role'
      )
    } 

    context "when email is invalid" do
      let(:invalid_emails) { ['invalid', 'invalid@', 'invalid@.com', '@invalid.com', 'invalid@invalid'] }

      it "should be invalid" do
        invalid_emails.each do |email|
          resource.email_address = email
          expect(resource.valid?).to eq(false)
        end
      end
    end

    context "when email is valid" do
      let(:valid_emails) { ['valid@example.com', 'valid.name@example.com', 'valid.name+tag@example.co.uk', 'valid-name@example.co.uk'] }
    
      it "should be valid" do
        valid_emails.each do |email|
          resource.email_address = email
          unless resource.valid?
            puts "Validation failed for email #{email}"
            puts resource.errors.full_messages
          end
          expect(resource.valid?).to eq(true)
        end
      end
    end

    describe "Conditionally validating email_address" do
      it "should validate email_address when validate_email_address is set to true" do
        subject.validate_email_address = true
        expect(subject.validate_email_address?).to eq(true)
      end
    end

    describe "Conditionally validating phone number" do
      it "should validate phone number when validate_phone_number is set to true" do
        subject.validate_phone_number = true
        expect(subject.validate_phone_number?).to eq(true)
      end
    end

  end
end