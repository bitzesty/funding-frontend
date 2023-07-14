require "rails_helper"

RSpec.describe FundingApplication::GpProject::AccountsController do

  login_user

  let(:funding_application) {
    create(
      :funding_application,
      organisation: subject.current_user.organisations.first
    )
  }

  describe "GET #show" do

    it "should render the page successfully for a valid project" do
      get :show,
          params: { application_id: funding_application.id }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
      expect(assigns(:funding_application).project.errors.empty?).to eq(true)
    end

    it "should redirect to root for an invalid project" do
      get :show, params: { application_id: "invalid" }
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:root)
    end

  end

  describe "PUT #update" do

    it "should re-render the show template if no params are passed" do

      put :update, params: { application_id: funding_application.id }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).project.errors.empty?).to eq(false)
      expect(assigns(:funding_application).project.errors.messages[:accounts_files][0])
          .to eq(I18n.t("activerecord.errors.models.project.attributes.accounts_files.inclusion"))

    end

    it "should re-render the show template if an empty project param is " \
       "passed" do

      put :update,
          params: {
              application_id: funding_application.id,
              project: { }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).project.errors.empty?).to eq(false)
      expect(assigns(:funding_application).project.errors.messages[:accounts_files][0])
          .to eq(I18n.t("activerecord.errors.models.project.attributes.accounts_files.inclusion"))

    end

    it "should re-render the show template if an invalid file is " \
    "passed" do

    put :update,
    params: {
        application_id: funding_application.id,
        project: {
            accounts_files: [""]
        }
    }

    expect(response).to have_http_status(:success)
    expect(response).to render_template(:show)

    expect(assigns(:funding_application).project.errors.empty?).to eq(false)
    expect(assigns(:funding_application).project.errors.messages[:accounts_files][0])
        .to eq("Add accounts")

    end

    it "should successfully update if a single file is uploaded" do

      put :update,
          params: {
              application_id: funding_application.id,
              project: {
                  accounts_files: [
                      Rack::Test::UploadedFile.new(
                          "#{Rails.root}/spec/fixtures/files/example.txt"
                      )
                  ]
              }
          }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:funding_application_gp_project_accounts)

      expect(assigns(:funding_application).project.errors.empty?).to eq(true)
      expect(funding_application.project.accounts_files.present?).to eq(true)
      expect(funding_application.project.accounts_files.count).to eq(1)

    end

    it "should successfully update if multiple files are uploaded" do

      put :update,
          params: {
              application_id: funding_application.id,
              project: {
                  accounts_files: [
                      Rack::Test::UploadedFile.new(
                          "#{Rails.root}/spec/fixtures/files/example.txt"
                      ),
                      Rack::Test::UploadedFile.new(
                          "#{Rails.root}/spec/fixtures/files/example.txt"
                      )
                  ]
              }
          }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:funding_application_gp_project_accounts)

      expect(assigns(:funding_application).project.errors.empty?).to eq(true)
      expect(funding_application.project.accounts_files.present?).to eq(true)
      expect(funding_application.project.accounts_files.count).to eq(2)

    end

  end

end
