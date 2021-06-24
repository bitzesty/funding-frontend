require "rails_helper"

RSpec.describe Organisation::SignatoriesController do
  login_user

  describe "GET #show" do

    it "should render the page successfully for a valid organisation" do
      get :show,
          params: { organisation_id: subject.current_user.organisations.first.id }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
      expect(assigns(:organisation).errors.empty?).to eq(true)
    end

    it "should redirect to root for an invalid organisation" do
      get :show, params: { organisation_id: "invalid" }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:root)
    end

  end

  describe "PUT #update" do

    it "should raise an exception based on strong params validation if no " \
        "params are passed" do
      expect {
        put :update,
            params: { organisation_id: subject.current_user.organisations.first.id }
      }.to raise_error(
               ActionController::ParameterMissing,
               "param is missing or the value is empty: organisation"
           )
    end

    it "should raise an exception based on strong params validation if an " \
       "empty organisation param is passed" do
      expect {
        put :update,
            params: {
                organisation_id: subject.current_user.organisations.first.id,
                organisation: {}
            }
      }.to raise_error(
               ActionController::ParameterMissing,
               "param is missing or the value is empty: organisation"
           )
    end

    it "should re-render the page if empty params are passed for both " \
       "legal signatories, with errors present for only the first" do

      put :update,
          params: {
              organisation_id: subject.current_user.organisations.first.id,
              organisation: {
                  legal_signatories_attributes: {
                      "0": {
                          name: "",
                          email_address: "",
                          phone_number: ""
                      },
                      "1": {
                          name: "",
                          email_address: "",
                          phone_number: ""
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:organisation).errors.empty?).to eq(false)

      # Checking the overall organisation errors hash first - these
      # are the errors that can occur.
      expect(assigns(:organisation).errors["legal_signatories"][0])
          .to eq("is invalid")
      expect(assigns(:organisation).errors["legal_signatories.name"][0])
          .to eq("Enter the name of a legal signatory")
      expect(assigns(:organisation)
                 .errors["legal_signatories.email_address"][0])
          .to eq("Enter a valid email address")
      expect(assigns(:organisation)
                 .errors["legal_signatories.phone_number"][0])
          .to eq("Enter the phone number of a legal signatory")

      # Checking the first legal signatories errors hash
      expect(assigns(:organisation)
                 .legal_signatories.first.errors.empty?).to eq(false)
      expect(assigns(:organisation)
                 .legal_signatories.first.errors[:name][0])
          .to eq("Enter the name of a legal signatory")
      expect(assigns(:organisation)
                 .legal_signatories.first.errors[:email_address][0])
          .to eq("Enter a valid email address")
      expect(assigns(:organisation)
                 .legal_signatories.first.errors[:phone_number][0])
          .to eq("Enter the phone number of a legal signatory")

      # Checking the second legal signatories errors hash
      expect(assigns(:organisation)
                 .legal_signatories.second.errors.empty?).to eq(false)
      expect(assigns(:organisation)
                 .legal_signatories.second.errors[:name][0])
          .to eq("Enter the name of a legal signatory")
      expect(assigns(:organisation)
                 .legal_signatories.second.errors[:email_address][0])
          .to eq("Enter a valid email address")
      expect(assigns(:organisation)
                 .legal_signatories.second.errors[:phone_number][0])
          .to eq("Enter the phone number of a legal signatory")

    end


    it "should re-render the page if a single non-empty param is passed for " \
       "the second legal signatory and empty params for the first, with " \
       "errors present for both" do

      put :update,
          params: {
              organisation_id: subject.current_user.organisations.first.id,
              organisation: {
                  legal_signatories_attributes: {
                      "0": {
                          name: "",
                          email_address: "",
                          phone_number: ""
                      },
                      "1": {
                          name: "Joe Bloggs",
                          email_address: "",
                          phone_number: ""
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:organisation).errors.empty?).to eq(false)

      # Checking the overall organisation errors hash first
      expect(assigns(:organisation).errors["legal_signatories"][0])
          .to eq("is invalid")
      expect(assigns(:organisation).errors["legal_signatories.name"][0])
          .to eq("Enter the name of a legal signatory")
      expect(assigns(:organisation)
                 .errors["legal_signatories.email_address"][0])
          .to eq("Enter a valid email address")
      expect(assigns(:organisation)
                 .errors["legal_signatories.phone_number"][0])
          .to eq("Enter the phone number of a legal signatory")

      # Checking the first legal signatories errors hash
      expect(assigns(:organisation).legal_signatories.first.errors.empty?)
          .to eq(false)
      expect(assigns(:organisation)
                 .legal_signatories.first.errors[:name][0])
          .to eq("Enter the name of a legal signatory")
      expect(assigns(:organisation)
                 .legal_signatories.first.errors[:email_address][0])
          .to eq("Enter a valid email address")
      expect(assigns(:organisation)
                 .legal_signatories.first.errors[:phone_number][0])
          .to eq("Enter the phone number of a legal signatory")

      # Checking the second legal signatories errors hash
      expect(assigns(:organisation).legal_signatories.second.errors.empty?)
          .to eq(false)
      expect(assigns(:organisation)
                 .legal_signatories.second.errors[:email_address][0])
          .to eq("Enter a valid email address")
      expect(assigns(:organisation)
                 .legal_signatories.second.errors[:phone_number][0])
          .to eq("Enter the phone number of a legal signatory")

    end

    it "should re-render the page if the first legal signatory added is " \
       "valid, but the second legal signatory is invalid" do

      put :update,
          params: {
              organisation_id: subject.current_user.organisations.first.id,
              organisation: {
                  legal_signatories_attributes: {
                      "0": {
                          name: "Joe Bloggs",
                          email_address: "joe@bloggs.com",
                          phone_number: "07123456789"
                      },
                      "1": {
                          name: "Jane Bloggs",
                          email_address: "",
                          phone_number: ""
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:organisation).errors.empty?).to eq(false)

      # Checking the overall organisation errors hash first
      expect(assigns(:organisation)
                 .errors["legal_signatories"][0]).to eq("is invalid")
      expect(assigns(:organisation)
                 .errors["legal_signatories.email_address"][0])
          .to eq("Enter a valid email address")
      expect(assigns(:organisation)
                 .errors["legal_signatories.phone_number"][0])
          .to eq("Enter the phone number of a legal signatory")

      # Checking the first legal signatories errors hash
      expect(assigns(:organisation)
                 .legal_signatories.first.errors.empty?).to eq(true)

      # Checking the second legal signatories errors hash
      expect(assigns(:organisation)
                 .legal_signatories.second.errors.empty?).to eq(false)
      expect(assigns(:organisation)
                 .legal_signatories.second.errors[:email_address][0])
          .to eq("Enter a valid email address")
      expect(assigns(:organisation)
                 .legal_signatories.second.errors[:phone_number][0])
          .to eq("Enter the phone number of a legal signatory")

    end

    it "should re-render the page if a single valid legal signatory is " \
       "added.  Two must be added." do

      put :update,
          params: {
              organisation_id: subject.current_user.organisations.first.id,
              organisation: {
                  legal_signatories_attributes: {
                      "0": {
                          name: "Joe Bloggs",
                          email_address: "joe@bloggs.com",
                          phone_number: "07123456789"
                      },
                      "1": {
                          name: "",
                          email_address: "",
                          phone_number: ""
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:organisation).errors.present?).to eq(true)

      expect(assigns(:organisation).legal_signatories.first.name)
          .to eq("Joe Bloggs")
      expect(assigns(:organisation).legal_signatories.first.email_address)
          .to eq("joe@bloggs.com")
      expect(assigns(:organisation).legal_signatories.first.phone_number)
          .to eq("07123456789")

      # Checking the second legal signatories errors hash
      expect(assigns(:organisation)
                 .legal_signatories.second.errors.empty?).to eq(false)
      expect(assigns(:organisation)
                 .legal_signatories.second.errors[:name][0])
          .to eq("Enter the name of a legal signatory")
      expect(assigns(:organisation)
                 .legal_signatories.second.errors[:email_address][0])
          .to eq("Enter a valid email address")
      expect(assigns(:organisation)
                 .legal_signatories.second.errors[:phone_number][0])
          .to eq("Enter the phone number of a legal signatory")

    end

    it "should successfully redirect if two valid legal signatories are " \
       "added" do

      put :update,
          params: {
              organisation_id: subject.current_user.organisations.first.id,
              organisation: {
                  legal_signatories_attributes: {
                      "0": {
                          name: "Joe Bloggs",
                          email_address: "joe@bloggs.com",
                          phone_number: "07123456789"
                      },
                      "1": {
                          name: "Jane Bloggs",
                          email_address: "jane@bloggs.com",
                          phone_number: "07987654321"
                      }
                  }
              }
          }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:organisation_summary)

      expect(assigns(:organisation).errors.empty?).to eq(true)

      expect(assigns(:organisation).legal_signatories.first.name)
          .to eq("Joe Bloggs")
      expect(assigns(:organisation).legal_signatories.first.email_address)
          .to eq("joe@bloggs.com")
      expect(assigns(:organisation).legal_signatories.first.phone_number)
          .to eq("07123456789")

      expect(assigns(:organisation).legal_signatories.second.name)
          .to eq("Jane Bloggs")
      expect(assigns(:organisation).legal_signatories.second.email_address)
          .to eq("jane@bloggs.com")
      expect(assigns(:organisation).legal_signatories.second.phone_number)
          .to eq("07987654321")

    end

    it "should not allow first signatory email to match second signatory email" do
      put :update,
          params: {
              organisation_id: subject.current_user.organisations.first.id,
              organisation: {
                  legal_signatories_attributes: {
                      "0": {
                          name: "Joe Bloggs",
                          email_address: "joe@bloggs.com",
                          phone_number: "07123456789"
                      },
                      "1": {
                          name: "Joe Bloggs",
                          email_address: "joe@bloggs.com",
                          phone_number: "07987654321"
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
      expect(assigns(:organisation)
                 .legal_signatories.second.errors[:email_address][0])
          .to eq("must be different to first signatory email address")
    end

  end

end
