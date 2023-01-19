module UserHelper

  # Checks for the presence of mandatory fields on a given user.
  # Returns true if all mandatory fields are present, otherwise
  # returns false.
  #
  # @param [User] user An instance of User
  def user_details_complete(user)

    user_details_fields_presence = []

    user_details_fields_presence.push(user.name.present?)
    user_details_fields_presence.push(user.date_of_birth.present?)
    user_details_fields_presence.push(
      (
        user.line1.present? &&
        user.townCity.present? &&
        user.county.present? &&
        user.postcode.present?
      )
    )

    user_details_fields_presence.all?

  end

  # import-todo rdoc - just grabs the most recent salesforce user with
  # matching email
  def populate_user_from_latest_salesforce_contact(user)

    # Populate from first user in result set (this could change)
    contact_restforce_collection =
      retrieve_existing_contact_info(user.email)

    populate_user_from_restforce_object(
      user,
      contact_restforce_collection.first
    )

  end


  # populates passed user with salesforce contact
  # @param [User] user An instance of User
  # @param [String] salesforce_contact_id Reference for Salesforce contact
  def populate_user_from_salesforce(user, salesforce_contact_id)

    contact_restforce =
      retrieve_existing_salesforce_contact(salesforce_contact_id)

    populate_user_from_restforce_object(user, contact_restforce)

  end

  private

  # Takes a Restforce collection for a Contact, and populates a User from it.
  # @param [User] user An instance of User (FFE)
  # @param [RestforceResponse] restforce_object A restforce collection frm SF.
  def populate_user_from_restforce_object(user, restforce_object)

    lines_array = ['', '', '']

    # MailingAddress nil when Account created with no address
    unless restforce_object.MailingAddress&.street&.nil?
      lines_array =
        restforce_object.MailingAddress.street.split(
          /\s*,\s*/
        )
    end

    user.line1 = lines_array[0]
    user.line2 = lines_array[1]
    user.line3 = lines_array[2]
    user.townCity = restforce_object.MailingAddress.city
    user.county = restforce_object.MailingAddress.state
    user.postcode = restforce_object.MailingAddress.postalCode

    user.name = restforce_object.LastName
    user.date_of_birth = restforce_object.Birthdate
    user.language_preference = restforce_object.Language_Preference__c
    user.phone_number = restforce_object.Phone
    user.salesforce_contact_id = restforce_object.Id
    user.agrees_to_user_research = restforce_object.Agrees_To_User_Research__c
    user.communication_needs = restforce_object.Other_communication_needs_for_contact__c
    user.save

  end

end
