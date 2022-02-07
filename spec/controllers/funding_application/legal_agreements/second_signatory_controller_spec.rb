require "rails_helper"

RSpec.describe FundingApplication::LegalAgreements::SecondSignatoryController do
  login_user

  describe "GET #show" do

    before do

      @funding_application = create(
        :funding_application,
        organisation_id: subject.current_user.organisations.first.id,
        id: 1
      )
          
      @legal_signatory_1 = create(
        :legal_signatory,
        name: "John Smith",
        email_address: "test@me.com",
        role: "Trustee",
        id: 1
      )
    
      @funding_application_legal_signatory = create(
        :funding_applications_legal_sig,
        funding_application_id: @funding_application.id,
        legal_signatory_id: @legal_signatory_1.id,
        id: 1
      )
      
   end

    it "should render the page with funding applications legal signatories if they exist" do
      get :show, params: { application_id: @funding_application.id }
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
    

    before do

      @funding_application = create(
        :funding_application,
        organisation_id: subject.current_user.organisations.first.id,
        id: 1
      )
          
      @legal_signatory_1 = create(
        :legal_signatory,
        name: "John Smith",
        email_address: "test@me.com",
        role: "Trustee",
        id: 1
      )
    
      @funding_application_legal_signatory = create(
        :funding_applications_legal_sig,
        funding_application_id: @funding_application.id,
        legal_signatory_id: @legal_signatory_1.id,
        id: 1
      )
          
    end

   
    it "should re-render the page if empty params are passed for second" \
    "legal signatory, with errors present" do

        put :update,
            params: {
              application_id: @funding_application.id,
              legal_signatory: {}
            }

        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)

        expect(assigns(:funding_application).errors.empty?).to eq(false)
      
        expect(assigns(:funding_application).errors[:"legal_signatories.role"][0])
          .to eq("Enter the role of a legal signatory")

        expect(assigns(:funding_application).errors[:"legal_signatories.name"][0])
          .to eq("Enter the name of a legal signatory")
        
        expect(assigns(:funding_application).errors[:"legal_signatories.email_address"][0])
          .to eq("Enter a valid email address")

    end
  

  
    it "should raise error for every field based on params validation if " \
    "empty fields are submitted" do

      put :update,
          params: {
            application_id: @funding_application.id,
            legal_signatory:{
              name: "",
              email_address: "",
              role: ""
            }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).errors.empty?).to eq(false)

      expect(assigns(:funding_application).errors[:"legal_signatories.role"][0])
          .to eq("Enter the role of a legal signatory")

      expect(assigns(:funding_application).errors[:"legal_signatories.name"][0])
        .to eq("Enter the name of a legal signatory")
      
      expect(assigns(:funding_application).errors[:"legal_signatories.email_address"][0])
        .to eq("Enter a valid email address")

    end

      
    it "should raise email error based on invalid email validation " \
    "when invalid email is passed" do

      put :update,
          params: {
            application_id: @funding_application.id,
            legal_signatory:{
              name: "John Smith",
              email_address: "john.smith.com",
              role: "Trustee"
            }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).errors.empty?).to eq(false)
      
      expect(assigns(:funding_application).errors.count)
        .to eq(1)

      expect(assigns(:funding_application).errors[:"legal_signatories.email_address"][0])
        .to eq("Enter a valid email address")

    end

    it "should raise email error based matching email address of " \
      "legal signatory 1 and legal signatory 2" do

      put :update,
          params: {
            application_id: @funding_application.id,
            legal_signatory:{
              name: "John Smith",
              email_address: @legal_signatory_1.email_address,
              role: "Trustee"
            }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).errors.empty?).to eq(false)
      
      expect(assigns(:funding_application).errors.count)
        .to eq(1)

      expect(assigns(:funding_application).errors[:"signatory_emails_unique"][0])
        .to eq("Email address should be different for each signatory and should be different to the applicant's")

    end


    it "should successfully redirect if two valid legal signatories are " \
       "added" do

      salesforce_stub

      put :update,
          params: {
            application_id: @funding_application.id,
            legal_signatory:{
              name: "Jane Bloggs",
              email_address: "jane@bloggs.com",
              role: "Owner"
            }
          }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:funding_application_terms_and_conditions)

      expect(assigns(:funding_application).errors.empty?).to eq(true)

      expect(assigns(:funding_application).legal_signatories.second.name)
          .to eq("Jane Bloggs")
      expect(assigns(:funding_application).legal_signatories.second.email_address)
          .to eq("jane@bloggs.com")
      expect(assigns(:funding_application).legal_signatories.second.role)
          .to eq("Owner")

    end

  end

end
