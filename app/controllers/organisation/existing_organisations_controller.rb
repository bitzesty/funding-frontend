# Controller that consider existing Salesforce Accounts, before
# asking an applicant to complete organisation info again
class Organisation::ExistingOrganisationsController < ApplicationController
  include ImportHelper
  before_action :authenticate_user!
  
  def show
    org = Organisation.find(params['organisation_id'])
    @orgs = retrieve_matching_sf_orgs(org)
  end

end
