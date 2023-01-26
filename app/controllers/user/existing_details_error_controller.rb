# Controller that consider existing Salesforce Contacts, before
# asking an applicant to complete user info again.
class User::ExistingDetailsErrorController < ApplicationController
  before_action :authenticate_user!

end
