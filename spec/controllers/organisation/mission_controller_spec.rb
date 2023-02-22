require "rails_helper"

RSpec.describe Organisation::MissionController do
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

    it "should successfully redirect to signatories if no params are passed" do
      put :update,
          params: { organisation_id: subject.current_user.organisations.first.id }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:organisation_summary)
    end

    it "should re-render the page if a single invalid param is passed" do

      expect(subject).to \
        receive(:log_errors)

      put :update, params: {
          organisation_id: subject.current_user.organisations.first.id,
          organisation: {
              mission: ["invalid_value"]
          }
      }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:organisation).errors.empty?).to eq(false)
      expect(
          assigns(:organisation).errors.messages[:mission][0]
      ).to eq("invalid_value is not a valid selection")

    end

    it "should re-render the page if a combination of invalid and " \
       "valid params are passed" do

      expect(subject).to \
        receive(:log_errors)

      put :update, params: {
          organisation_id: subject.current_user.organisations.first.id,
          organisation: {
              mission: ["invalid_value", "female_led"]
          }
      }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:organisation).errors.empty?).to eq(false)
      expect(
          assigns(:organisation).errors.messages[:mission][0]
      ).to eq("invalid_value is not a valid selection")

    end

    it "should successfully update if a single valid param is passed" do

      put :update, params: {
          organisation_id: subject.current_user.organisations.first.id,
          organisation: {
              mission: ["female_led"]
          }
      }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:organisation_summary)

      expect(assigns(:organisation).errors.empty?).to eq(true)
      expect(assigns(:organisation).mission).to eq(["female_led"])

    end

    it "should successfully update if multiple valid params are passed" do

      put :update, params: {
          organisation_id: subject.current_user.organisations.first.id,
          organisation: {
              mission: ["female_led", "lgbt_plus_led"]
          }
      }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:organisation_summary)

      expect(assigns(:organisation).errors.empty?).to eq(true)
      expect(assigns(:organisation)
              .mission).to eq(["female_led", "lgbt_plus_led"])

    end

  end

end
