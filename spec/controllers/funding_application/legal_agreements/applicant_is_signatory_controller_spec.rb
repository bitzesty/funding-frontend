require "rails_helper"

RSpec.describe FundingApplication::LegalAgreements::ApplicantIsSignatoryController do
  login_user

  let(:funding_application) {
    create(
      :funding_application,
      id: 'id',
      organisation_id: subject.current_user.organisations.first.id,
    )
  }

  describe "GET #show" do

    before do

        subject.current_user.organisations.first.update(
         name: 'Test Organisation',
         line1: '10 Downing Street',
         line2: 'Westminster',
         townCity: 'London',
         county: 'London',
         postcode: 'SW1A 2AA',
         org_type: 1
       )
      
   end

    it "should render the page with funding applications legal signatory if they exist" do
      get :show, params: { application_id: funding_application.id }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
      expect(assigns(:funding_application).errors.empty?).to eq(true)
    end

    it "implicit check that funding_application_context.rb called" do
      get :show, params: { application_id: 'missing_id' }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:root)
    end

  end

  describe "PUT #update" do
    it "should raise an exception based on strong params validation if no " \
        "params are passed" do
 
        put :update,
                params: {
                application_id: funding_application.id
                }
    
            expect(response).to have_http_status(:success)
            expect(response).to render_template(:show)
            expect(assigns(:funding_application).errors.empty?).to eq(false)
            expect(assigns(:funding_application).errors["applicant_is_legal_sig"][0])
                .to eq("Please select an option")
    end

    it "should raise an error based on strong params validation if an " \
       "empty funding_application param is passed" do

        put :update,
                params: {
                application_id: funding_application.id,
                funding_application: { }
                }
    
            expect(response).to have_http_status(:success)
            expect(response).to render_template(:show)
            expect(assigns(:funding_application).errors.empty?).to eq(false)
            expect(assigns(:funding_application).errors["applicant_is_legal_sig"][0])
                .to eq("Please select an option")
    end
  

    it "should re-render the page if applicant is legal sig but no role is provided, " \
       "with an error present against the funding_application" do

      put :update,
          params: {
            application_id: funding_application.id,
              funding_application: {
                 applicant_is_legal_sig: "true"
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).errors.empty?).to eq(false)

      expect(assigns(:funding_application).errors["applicant_role"][0])
                .to eq("Please add your role in the organisation")
    end

    it "should successfully redirect if valid legal signatory is added " \
     do

      salesforce_stub

      put :update,
          params: {
            application_id: funding_application.id,
              funding_application: {
                 applicant_is_legal_sig: "true", 
                 applicant_role: "Trustee"
              }
          }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:funding_application_second_signatory)

      expect(assigns(:funding_application).errors.empty?).to eq(true)

      expect(assigns(:funding_application).legal_signatories.first.name)
          .to eq("Joe Bloggs")
      expect(assigns(:funding_application).legal_signatories.first.email_address)
          .to eq(subject.current_user.email)
      expect(assigns(:funding_application).legal_signatories.first.role)
          .to eq("Trustee")
    end
  end
end
