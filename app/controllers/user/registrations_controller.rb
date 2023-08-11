# Controller for the page that captures user registration details.
class User::RegistrationsController < Devise::RegistrationsController

  # Override the Devise::RegistrationsController create method
  # resource refers to the User object being created
  def create

    super do

      # Check that the user model is valid so that we do not create an empty
      # Organisation or an empty Person if validation fails
      if resource.valid?

        create_person(resource)

      end

      resource.save

    end

  end

  def create_person(resource) 

    person = Person.create(email: resource.email)

    resource.organisations.create

    resource.person_id = person.id

    # send a copy of the confirmation instructions to support team
    NotifyMailer.confirmation_instructions_copy(resource).deliver_later

  end
  
  # Override the Devise::RegistrationsController update_resource method
  # Ensures the email is not provided as a param to prevent it being updated
  def update_resource(resource, params)
  
    params.delete(:email)

    super
  end

end
