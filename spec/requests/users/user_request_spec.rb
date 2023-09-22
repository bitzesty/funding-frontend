require 'rails_helper'

RSpec.describe "User", type: :request do

  # These tests ensure that the users path and redirects work
  describe "GET /users" do
    it "redirects to the root path" do
      get "/users"
      expect(response).to have_http_status(:redirect)
    end

    it "allows paths beyond /users" do
      get "/users/sign_up?"
      expect(response).to have_http_status(:success)
    end

  end

end