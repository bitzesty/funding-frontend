require "rails_helper"

RSpec.describe Organisation::NumbersController do
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
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(:organisation_signatories)
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
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(:organisation_signatories)
      }.to raise_error(
               ActionController::ParameterMissing,
               "param is missing or the value is empty: organisation"
           )
    end

    it "should successfully redirect to about if empty charity_number " \
    "and company_number params are passed and when import_existing_account disabled" do

      put :update, params: {
          organisation_id: subject.current_user.organisations.first.id,
          organisation: {
              charity_number: "",
              company_number: ""
          }
      }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(
                              postcode_path 'organisation',
                                            subject.current_user.organisations.first.id
                          )
      expect(assigns(:organisation).errors.empty?).to eq(true)

    end

    it "should successfully redirect to mission if empty charity_number " \
       "and company_number params are passed and import_existing_account enabled" do

      begin
        
        Flipper[:import_existing_account_enabled].enable

        put :update, params: {
            organisation_id: subject.current_user.organisations.first.id,
            organisation: {
                charity_number: "",
                company_number: ""
            }
        }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(
            organisation_mission_path(
              subject.current_user.organisations.first.id
            )
        )
        expect(assigns(:organisation).errors.empty?).to eq(true)

      ensure
        Flipper[:import_existing_account_enabled].disable
      end      

    end

    it "should successfully redirect to about if populated charity_number " \
    "and company_number params are passed and import_existing_account disabled" do

      put :update, params: {
          organisation_id: subject.current_user.organisations.first.id,
          organisation: {
              charity_number: "CHNO12345",
              company_number: "CONO54321"
          }
      }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(
                              postcode_path 'organisation',
                                            subject.current_user.organisations.first.id
                          )
      expect(assigns(:organisation).errors.empty?).to eq(true)
      expect(assigns(:organisation).charity_number).to eq("CHNO12345")
      expect(assigns(:organisation).company_number).to eq("CONO54321")
    end

    it "should successfully redirect to mission if populated charity_number " \
       "and company_number params are passed and import_existing_account enable" do

      begin
        
        Flipper[:import_existing_account_enabled].enable

        put :update, params: {
            organisation_id: subject.current_user.organisations.first.id,
            organisation: {
                charity_number: "CHNO12345",
                company_number: "CONO54321"
            }
        }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(
          organisation_mission_path (
              subject.current_user.organisations.first.id
          )
        )
        expect(assigns(:organisation).errors.empty?).to eq(true)
        expect(assigns(:organisation).charity_number).to eq("CHNO12345")
        expect(assigns(:organisation).company_number).to eq("CONO54321")

      ensure
        Flipper[:import_existing_account_enabled].disable
      end      

    end

    it "should re-render the show page with errors if the charity and " \
    "company numbers exceed 20 characters" do

      put :update, params: {
          organisation_id: subject.current_user.organisations.first.id,
          organisation: {
              charity_number: "CHNO123456789123456789",
              company_number: "CONO987654321987654321"
          }
      }

      expect(assigns(:organisation).charity_number).to eq("CHNO123456789123456789")
      expect(assigns(:organisation).company_number).to eq("CONO987654321987654321")

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:organisation).errors.present?).to eq(true)


      expect(
        assigns(:organisation).errors.messages[:charity_number][0]
      ).to eq(I18n.t("activerecord.errors.models.organisation.attributes." \
        "charity_number.too_long"))

      expect(
        assigns(:organisation).errors.messages[:company_number][0]
      ).to eq(I18n.t("activerecord.errors.models.organisation.attributes." \
        "company_number.too_long"))

    end

  end

end