# Controller that consider existing Salesforce Accounts, before
# asking an applicant to complete organisation info again
class Organisation::ExistingOrganisationsErrorController < ApplicationController
  include ImportHelper
  before_action :authenticate_user!
  
  def show
  end

end
