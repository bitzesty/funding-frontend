require 'rails_helper'

RSpec.describe OrganisationHelper do

  describe '#complete_organisation_details' do
    
    let (:legal_signatory) {
      create(
        :legal_signatory,
        id: '1',
        name: 'Joe Bloggs',
        email_address: 'joe@bloggs.com',
        phone_number: '07000000000'
      )
    }

    let (:organisation) {
      create(
        :organisation,
        id: '1',
        name: 'Test Organisation',
        line1: '10 Downing Street',
        line2: 'Westminster',
        townCity: 'London',
        county: 'London',
        postcode: 'SW1A 2AA',
        org_type: 1
      )
    }
  end

end
