class SalesforceExperienceApplication::ApprovedPurposesController < ApplicationController

  # consider a context here to retrieve the sfx row using case_id, then reuse across journey.

  def show
    @approved_purpose_match ={};

  end

  def update 
    salesforce_case_id = params.fetch(:salesforce_case_id)

    redirect_to(
      sfx_pts_payment_agreed_costs_path(salesforce_case_id)
    )
  end
end
