# Controller that consider existing Salesforce Contacts, before
# asking an applicant to complete user info again.
class User::ExistingDetailsController < ApplicationController
  before_action :authenticate_user!
  include UserHelper
  include ImportHelper

  def show

    @contact_restforce_collection =
      retrieve_existing_contact_info(current_user.email)

  end

  def update

    # Updates the current user with the most recently changed SF 
    # user with a matching email.
    populate_user_from_latest_salesforce_contact(current_user)

  end

end
