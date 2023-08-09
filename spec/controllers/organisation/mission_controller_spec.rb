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

    it "should successfully update if no mission params are passed" do

      put :update, params: {
          organisation_id: subject.current_user.organisations.first.id,
          organisation: {
              mission: []
          }
      }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:organisation_summary)

      expect(assigns(:organisation).errors.empty?).to eq(true)
      expect(assigns(:organisation)
              .mission).to eq([])

    end

  end

  # These tests specifically test the ensure_mission_params method
   describe '#ensure_mission_params' do
    
    before do
      controller.class.send(:public, :ensure_mission_params) # This makes the method available for testing as it is a private method
    end

    context 'when :organisation is present' do
      context 'when :mission is already set' do
        it 'does not change the mission' do
          params = {
            organisation: {
              mission: ["female_led"],
            }
          }
          allow(controller).to receive(:params).and_return(params)

          controller.ensure_mission_params

          expect(params[:organisation][:mission]).to eq(['female_led'])

        end

      end

    end
    
    context 'when :mission is not set' do
      it 'sets mission to an empty array' do
        params = {
          organisation: {}
        }
        allow(controller).to receive(:params).and_return(params)

        controller.ensure_mission_params

        expect(params[:organisation][:mission]).to eq([])

      end

    end

  end

end
