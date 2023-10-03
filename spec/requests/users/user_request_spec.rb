require 'rails_helper'

RSpec.describe "User", type: :request do

  # These tests ensure that the users path and redirects work
  describe "/users path does not exist and back button works as it should" do

    it "/users path dos not exist" do
      expect { get "/users" }.to raise_error(ActionController::RoutingError)
    end

    it "allows paths beyond /users" do
      get "/users/sign_up?"
      expect(response).to have_http_status(:success)
    end

  end

  # We are testing the devise workflows to ensure any redirects do 
  # not interfere with devise. 
  describe "Devise workflows" do
    let(:user_params) { { email: 'test@example.com', password: 'password', password_confirmation: 'password' } }
    let(:user) { User.create!(user_params) }

    after(:each) do
      User.destroy_all  # Clean up any created users
    end

    it "allows user to sign in" do
      post "/users/sign_in", params: { user: { email: user.email, password: 'password' } }
      expect(response).to redirect_to('http://www.example.com/users/sign_in') 
    end

    it "allows user to sign out" do
      # Sign in before trying to sign out
      post "/users/sign_in", params: { user: { email: user.email, password: 'password' } }
      delete "/users/sign_out"
      expect(response).to redirect_to('http://www.example.com/?locale=en-GB')  
    end

    it "allows user to register" do
      # Only run this test if registration is enabled
      if Flipper.enabled?(:registration_enabled)
        post "/users", params: { user: user_params }
        expect(response).to redirect_to(root_path) 
      end
    end
  end

end
