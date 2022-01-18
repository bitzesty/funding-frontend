require 'rails_helper'

RSpec.describe User::RegistrationsController  do
 
  describe '#create_person' do
    
    let (:resource) {
      create(
        :user,
        id: 1,
        email: 'a@f.com',
        confirmation_token: 'zsdfasd23e123'
      )
    } 

    it "creates a person object, an organisations object and sends a copy" \
     "of the confirmation instructions" do

      expect(Person).to receive(:create).with(email: resource.email) \
        {resource.person}

      expect(resource.organisations).to receive(:create)

      expect(resource.person_id).to eq(resource.person.id)

      expect(NotifyMailer).to receive_message_chain(
        :confirmation_instructions_copy, :deliver_later
      )

      subject.create_person(resource)
    end
  end
end
