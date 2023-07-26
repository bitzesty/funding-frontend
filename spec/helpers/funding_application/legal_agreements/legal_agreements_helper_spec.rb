require 'rails_helper'

include LegalAgreementsHelper

RSpec.describe LegalAgreementsHelper do

  describe "#send_legal_signatory_email" do

    let (:legal_signatory) {
      create(
        :legal_signatory,
        id: "1",
        name: "Joe Bloggs",
        email_address: "joe@bloggs.com",
        phone_number: "07000000000"
      )
    }

    let(:funding_application) {
      create(
        :funding_application,
        id: "id"
      )
    }

    it "sends logs correctly" do

      allow_any_instance_of(LegalAgreementsHelper).to receive(
        :encode_legal_signatory_id).with(
          legal_signatory.id).and_return(
            "an encoded signatory id")
      
      allow_any_instance_of(LegalAgreementsHelper).to receive(
        :build_agreement_link).with(
          funding_application.id, "an encoded signatory id").and_return(
            "an encoded link")

      # Params for send_legal_signatory_email not checked as two calls made
      # with differing params
      allow_any_instance_of(LegalAgreementsHelper).to receive(:send_legal_signatory_email)

      # .ordered ensures many calls to the same function are checked in order
      expect(Rails.logger).to receive(:info).with(
        "Sig link mail sent for legal_signatory.id #{legal_signatory.id} " \
          "and for funding_application ID: #{funding_application.id}"
      ).ordered

      expect(Rails.logger).to receive(:info).with(
        "Support copy of link mail sent for legal_signatory.id " \
          "#{legal_signatory.id} and " \
            "for funding_application ID: #{funding_application.id}"
      ).ordered

      # run the function, now that the expectations are set
      send_legal_signatory_link_emails(funding_application, legal_signatory)

    end

  end

end
