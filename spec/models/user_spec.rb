require "rails_helper"

RSpec.describe User, type: :model do

  describe "User model" do

    let (:resource) {
      create(
        :user,
        id: 1,
        email: 'a@f.com',
        confirmation_token: 'zsdfasd23e123',
        language_preference: "both"
      )
    } 

    it "should return the correct boolean results for the functions " \
      "that check what email language is needed " \
        "when language preferences are set to both" do
    
        expect(resource.send_bilingual_mails?).to eq(true)
        expect(resource.send_english_mails?).to eq(false)
        expect(resource.send_welsh_mails?).to eq(false)

    end

    it "should return the correct boolean results for the functions " \
    "that check what email language is needed " \
      "when language preferences are set to welsh" do

      resource.language_preference = 'welsh'  
  
      expect(resource.send_bilingual_mails?).to eq(false)
      expect(resource.send_english_mails?).to eq(false)
      expect(resource.send_welsh_mails?).to eq(true)

    end

    it "should return the correct boolean results for the functions " \
    "that check what email language is needed " \
      "when language preferences are set to english" do

      resource.language_preference = 'english'  
  
      expect(resource.send_bilingual_mails?).to eq(false)
      expect(resource.send_english_mails?).to eq(true)
      expect(resource.send_welsh_mails?).to eq(false)

    end

    it "should return true for send_english_mails " \
      "when language preferences are null" do

      resource.language_preference = nil  
  
      expect(resource.send_bilingual_mails?).to eq(false)
      expect(resource.send_english_mails?).to eq(true)
      expect(resource.send_welsh_mails?).to eq(false)

    end

    it "should return true for send_english_mails " \
      "when language preferences are null" do

        resource.language_preference = nil  

        expect(resource.send_bilingual_mails?).to eq(false)
        expect(resource.send_english_mails?).to eq(true)
        expect(resource.send_welsh_mails?).to eq(false)

    end

    it "should return the correct boolean results for the functions " \
      "that check what email language is needed " \
        "when language preferences are mixed case with extra whitespace" do

      resource.language_preference = ' eNglISh '  
      expect(resource.send_english_mails?).to eq(true)

      resource.language_preference = ' WELsh   '
      expect(resource.send_welsh_mails?).to eq(true)

      resource.language_preference = 'Both   '
      expect(resource.send_bilingual_mails?).to eq(true)
  
    end

    it "should only return true for send_english_mails? " \
      "when an unknown language preference is used." do

      resource.language_preference = 'cornish'  
      expect(resource.send_english_mails?).to eq(true)
      expect(resource.send_welsh_mails?).to eq(false)
      expect(resource.send_bilingual_mails?).to eq(false)
    end    


    context "when email is invalid" do
      let(:invalid_emails) { ['invalid', 'invalid@', 'invalid@.com', '@invalid.com', 'invalid@invalid'] }

      it "should be invalid" do
        invalid_emails.each do |email|
          resource.email = email
          expect(resource.valid?).to eq(false)
        end
      end
    end

    context "when email is valid" do
      let(:valid_emails) { ['valid@example.com', 'valid.name@example.com', 'valid.name+tag@example.co.uk', 'valid-name@example.co.uk'] }
    
      it "should be valid" do
        valid_emails.each do |email|
          resource.email = email
          expect(resource.valid?).to eq(true)
        end
      end
    end

  end
end
