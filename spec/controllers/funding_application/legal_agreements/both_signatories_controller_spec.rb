require "rails_helper"

RSpec.describe FundingApplication::LegalAgreements::BothSignatoriesController do
  login_user

  let(:funding_application) {
    create(
      :funding_application,
      id: 'id',
      organisation_id: subject.current_user.organisations.first.id,
      # open_medium: OpenMedium.create(),
      # submitted_on: DateTime.now()
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

    it "should render the page with funding applications legal signatories if they exist" do
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
      expect {
        put :update,
            params: { 
              application_id: funding_application.id            }
      }.to raise_error(
               ActionController::ParameterMissing,
               "param is missing or the value is empty: funding_application"
           )
    end

    it "should raise an exception based on strong params validation if an " \
       "empty funding_application param is passed" do
      expect {
        put :update,
            params: { 
              application_id: funding_application.id,
              funding_application: {} 
            }
      }.to raise_error(
                ActionController::ParameterMissing,
                "param is missing or the value is empty: funding_application"
            )
    end
  

    it "should re-render the page if empty params are passed for both " \
       "legal signatories, with errors present for both signatories" do

      put :update,
          params: {
            application_id: funding_application.id,
              funding_application: {
                  legal_signatories_attributes: {
                      "0": {
                          name: "",
                          email_address: "",
                          role: ""
                      },
                      "1": {
                          name: "",
                          email_address: "",
                          role: ""
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).errors.empty?).to eq(false)

      # Checking the overall organisation errors hash first - these
      # are the errors that can occur.
      expect(assigns(:funding_application).errors["legal_signatories"][0])
          .to eq("is invalid")
      expect(assigns(:funding_application).errors["legal_signatories.name"][0])
          .to eq("Enter the name of a legal signatory")
      expect(assigns(:funding_application)
                 .errors["legal_signatories.email_address"][0])
          .to eq("Enter a valid email address")
      expect(assigns(:funding_application)
                 .errors["legal_signatories.role"][0])
          .to eq("Enter the role of a legal signatory")

      # Checking the first legal signatories errors hash
      expect(assigns(:funding_application)
                 .legal_signatories.first.errors.empty?).to eq(false)
      expect(assigns(:funding_application)
                 .legal_signatories.first.errors[:name][0])
          .to eq("Enter the name of a legal signatory")
      expect(assigns(:funding_application)
                 .legal_signatories.first.errors[:email_address][0])
          .to eq("Enter a valid email address")
      expect(assigns(:funding_application)
                 .legal_signatories.first.errors[:role][0])
          .to eq("Enter the role of a legal signatory")

      # Checking the second legal signatories errors hash
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors.empty?).to eq(false)
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors[:name][0])
          .to eq("Enter the name of a legal signatory")
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors[:email_address][0])
          .to eq("Enter a valid email address")
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors[:role][0])
          .to eq("Enter the role of a legal signatory")

    end


    it "should re-render the page if a single non-empty param is passed for " \
       "the second legal signatory and empty params for the first, with " \
       "errors present for both" do

      put :update,
          params: {
            application_id: funding_application.id,
            funding_application: {
                legal_signatories_attributes: {
                    "0": {
                        name: "",
                        email_address: "",
                        role: ""
                    },
                    "1": {
                        name: "Joe Bloggs",
                        email_address: "",
                        role: ""
                    }
                }
            }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).errors.empty?).to eq(false)

      # Checking the overall funding_application errors hash first
      expect(assigns(:funding_application).errors["legal_signatories"][0])
          .to eq("is invalid")
      expect(assigns(:funding_application).errors["legal_signatories.name"][0])
          .to eq("Enter the name of a legal signatory")
      expect(assigns(:funding_application)
                 .errors["legal_signatories.email_address"][0])
          .to eq("Enter a valid email address")
      expect(assigns(:funding_application)
                 .errors["legal_signatories.role"][0])
          .to eq("Enter the role of a legal signatory")

      # Checking the first legal signatories errors hash
      expect(assigns(:funding_application).legal_signatories.first.errors.empty?)
          .to eq(false)
      expect(assigns(:funding_application)
                 .legal_signatories.first.errors[:name][0])
          .to eq("Enter the name of a legal signatory")
      expect(assigns(:funding_application)
                 .legal_signatories.first.errors[:email_address][0])
          .to eq("Enter a valid email address")
      expect(assigns(:funding_application)
                 .legal_signatories.first.errors[:role][0])
          .to eq("Enter the role of a legal signatory")

      # Checking the second legal signatories errors hash
      expect(assigns(:funding_application).legal_signatories.second.errors.empty?)
          .to eq(false)
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors[:email_address][0])
          .to eq("Enter a valid email address")
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors[:role][0])
          .to eq("Enter the role of a legal signatory")

    end

    it "should re-render the page if the first legal signatory added is " \
       "valid, but the second legal signatory is invalid" do

      put :update,
          params: {
            application_id: funding_application.id,
            funding_application: {
                  legal_signatories_attributes: {
                      "0": {
                          name: "Joe Bloggs",
                          email_address: "joe@bloggs.com",
                          role: "Trustee"
                      },
                      "1": {
                          name: "Jane Bloggs",
                          email_address: "",
                          role: ""
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).errors.empty?).to eq(false)

      # Checking the overall funding_application errors hash first
      expect(assigns(:funding_application)
                 .errors["legal_signatories"][0]).to eq("is invalid")
      expect(assigns(:funding_application)
                 .errors["legal_signatories.email_address"][0])
          .to eq("Enter a valid email address")
      expect(assigns(:funding_application)
                 .errors["legal_signatories.role"][0])
          .to eq("Enter the role of a legal signatory")

      # Checking the first legal signatories errors hash
      expect(assigns(:funding_application)
                 .legal_signatories.first.errors.empty?).to eq(true)

      # Checking the second legal signatories errors hash
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors.empty?).to eq(false)
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors[:email_address][0])
          .to eq("Enter a valid email address")
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors[:role][0])
          .to eq("Enter the role of a legal signatory")

    end

    it "should re-render the page if a single valid legal signatory is " \
       "added.  Two must be added." do

      put :update,
          params: {
              application_id:  funding_application.id,
              funding_application: {
                  legal_signatories_attributes: {
                      "0": {
                          name: "Joe Bloggs",
                          email_address: "joe@bloggs.com",
                          role: "Trustee"
                      },
                      "1": {
                          name: "",
                          email_address: "",
                          role: ""
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).errors.present?).to eq(true)

      expect(assigns(:funding_application).legal_signatories.first.name)
          .to eq("Joe Bloggs")
      expect(assigns(:funding_application).legal_signatories.first.email_address)
          .to eq("joe@bloggs.com")
      expect(assigns(:funding_application).legal_signatories.first.role)
          .to eq("Trustee")

      # Checking the second legal signatories errors hash
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors.empty?).to eq(false)
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors[:name][0])
          .to eq("Enter the name of a legal signatory")
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors[:email_address][0])
          .to eq("Enter a valid email address")
      expect(assigns(:funding_application)
                 .legal_signatories.second.errors[:role][0])
          .to eq("Enter the role of a legal signatory")

    end

    it "should successfully redirect if two valid legal signatories are " \
       "added" do

      salesforce_stub

      put :update,
          params: {
              application_id: funding_application.id,
              funding_application: {
                  legal_signatories_attributes: {
                      "0": {
                          name: "Joe Bloggs",
                          email_address: "joe@bloggs.com",
                          role: "Trustee"
                      },
                      "1": {
                          name: "Jane Bloggs",
                          email_address: "jane@bloggs.com",
                          role: "Owner"
                      }
                  }
              }
          }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:funding_application_awaiting_signatories)

      expect(assigns(:funding_application).errors.empty?).to eq(true)

      expect(assigns(:funding_application).legal_signatories.first.name)
          .to eq("Joe Bloggs")
      expect(assigns(:funding_application).legal_signatories.first.email_address)
          .to eq("joe@bloggs.com")
      expect(assigns(:funding_application).legal_signatories.first.role)
          .to eq("Trustee")

      expect(assigns(:funding_application).legal_signatories.second.name)
          .to eq("Jane Bloggs")
      expect(assigns(:funding_application).legal_signatories.second.email_address)
          .to eq("jane@bloggs.com")
      expect(assigns(:funding_application).legal_signatories.second.role)
          .to eq("Owner")

    end

    it "should not allow first signatory email to match second signatory email" do
      put :update,
          params: {
            application_id: funding_application.id,
            funding_application: {
                  legal_signatories_attributes: {
                      "0": {
                          name: "Joe Bloggs",
                          email_address: "joe@bloggs.com",
                          role: "Trustee"
                      },
                      "1": {
                          name: "Jane Bloggs",
                          email_address: "joe@bloggs.com",
                          role: "Owner"
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
      expect(assigns(:funding_application).errors[:signatory_emails_unique][0])
          .to eq(I18n.t('agreement.both_signatories.signatory_emails_unique_error'))
    end

  end

end
