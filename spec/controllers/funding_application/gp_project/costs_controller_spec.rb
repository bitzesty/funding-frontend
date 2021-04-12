require "rails_helper"

RSpec.describe FundingApplication::GpProject::CostsController do

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

    it "should raise a ParameterMissing error if no project param is passed" do

      expect {
        put :update,
            params: { application_id: funding_application.id }
      }.to raise_error(
               ActionController::ParameterMissing,
               "param is missing or the value is empty: project"
           )

    end

    it "should raise a ParameterMissing error if an empty project param " \
       "is passed" do

      expect {
        put :update,
            params: {
                application_id: funding_application.id,
                project: { }
            }
      }.to raise_error(
               ActionController::ParameterMissing,
               "param is missing or the value is empty: project"
           )

    end

    it "should re-render the page if empty attributes are passed" do

      expect(subject).to \
        receive(:log_errors).with(funding_application.project)

      put :update,
          params: {
              application_id: funding_application.id,
              project: {
                  project_costs_attributes: {
                      "0": {
                          cost_type: "",
                          description: "",
                          amount: ""
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).project.errors.empty?).to eq(false)
      expect(assigns(:funding_application).project.project_costs.first.errors.empty?)
          .to eq(false)
      expect(assigns(:funding_application).project.project_costs.first.errors.messages[:cost_type][0])
          .to eq(I18n.t("activerecord.errors.models.project_cost.attributes.cost_type.blank"))
      expect(assigns(:funding_application).project.project_costs.first.errors.messages[:amount][0])
          .to eq(I18n.t("activerecord.errors.models.project_cost.attributes.amount.not_a_number"))
      expect(assigns(:funding_application).project.project_costs.first.errors.messages[:description][0])
          .to eq(I18n.t("activerecord.errors.models.project_cost.attributes.description.blank"))

    end

    it "should raise an ArgumentError exception if an invalid cost_type " \
       "attribute is passed" do

      expect {

        put :update,
            params: {
                application_id: funding_application.id,
                project: {
                    project_costs_attributes: {
                        "0": {
                            cost_type: "invalid",
                            description: "",
                            amount: ""
                        }
                    }
                }
            }

      }.to raise_error(
               ArgumentError,
               "'invalid' is not a valid cost_type"
           )

    end

    it "should re-render the page if a description attribute which exceeds " \
       "the max length is passed" do

      expect(subject).to \
        receive(:log_errors).with(funding_application.project)

      put :update,
          params: {
              application_id: funding_application.id,
              project: {
                  project_costs_attributes: {
                      "0": {
                          cost_type: "new_staff",
                          description: "word " * 51,
                          amount: "100"
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).project.errors.empty?).to eq(false)
      expect(assigns(:funding_application).project.project_costs.first.errors.empty?)
          .to eq(false)
      expect(assigns(:funding_application).project.project_costs.first.errors.messages[:description][0])
          .to eq(I18n.t("activerecord.errors.models.project_cost.attributes.description.too_long", word_count: 50))

    end

    it "should re-render the page if an amount attribute which is not " \
       "an integer is passed" do

      expect(subject).to \
        receive(:log_errors).with(funding_application.project)

      put :update,
          params: {
              application_id: funding_application.id,
              project: {
                  project_costs_attributes: {
                      "0": {
                          cost_type: "new_staff",
                          description: "Test",
                          amount: "string"
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).project.errors.empty?).to eq(false)
      expect(assigns(:funding_application).project.project_costs.first.errors.empty?)
          .to eq(false)
      expect(assigns(:funding_application).project.project_costs.first.errors.messages[:amount][0])
          .to eq(I18n.t("activerecord.errors.models.project_cost.attributes.amount.not_a_number"))

    end

    it "should re-render the page if an amount attribute which contains a " \
       "negative number is passed" do

      expect(subject).to \
        receive(:log_errors).with(funding_application.project)

      put :update,
          params: {
              application_id: funding_application.id,
              project: {
                  project_costs_attributes: {
                      "0": {
                          cost_type: "new_staff",
                          description: "Test",
                          amount: "-50"
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).project.errors.empty?).to eq(false)
      expect(assigns(:funding_application).project.project_costs.first.errors.empty?)
          .to eq(false)
      expect(assigns(:funding_application).project.project_costs.first.errors.messages[:amount][0])
          .to eq(I18n.t("activerecord.errors.models.project_cost.attributes.amount.greater_than"))

    end

    it "should re-render the page with a flash message if empty " \
       "description and populated amount attributes are passed" do

      expect(subject).to \
        receive(:log_errors).with(funding_application.project)

      put :update,
          params: {
              application_id: funding_application.id,
              project: {
                  project_costs_attributes: {
                      "0": {
                          cost_type: "new_staff",
                          description: "",
                          amount: "5"
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(subject.request.flash[:amount]).to eq("5")
      expect(subject.request.flash[:cost_type]).to eq("new_staff")

      expect(assigns(:funding_application).project.errors.empty?).to eq(false)
      expect(assigns(:funding_application).project.project_costs.first.errors.empty?)
          .to eq(false)
      expect(assigns(:funding_application).project.project_costs.first.errors.messages[:description][0])
          .to eq(I18n.t("activerecord.errors.models.project_cost.attributes.description.blank"))

    end

    it "should re-render the page with a flash message if empty " \
       "amount and populated description attributes are passed" do

      expect(subject).to \
        receive(:log_errors).with(funding_application.project)

      put :update,
          params: {
              application_id: funding_application.id,
              project: {
                  project_costs_attributes: {
                      "0": {
                          cost_type: "new_staff",
                          description: "Test",
                          amount: ""
                      }
                  }
              }
          }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(subject.request.flash[:description]).to eq("Test")
      expect(subject.request.flash[:cost_type]).to eq("new_staff")

      expect(assigns(:funding_application).project.errors.empty?).to eq(false)
      expect(assigns(:funding_application).project.project_costs.first.errors.empty?)
          .to eq(false)
      expect(assigns(:funding_application).project.project_costs.first.errors.messages[:amount][0])
          .to eq(I18n.t("activerecord.errors.models.project_cost.attributes.amount.not_a_number"))

    end

    it "should successfully update if valid attributes are passed" do

      put :update,
          params: {
              application_id: funding_application.id,
              project: {
                  project_costs_attributes: {
                      "0": {
                          cost_type: "new_staff",
                          description: "Test",
                          amount: "1000"
                      }
                  }
              }
          }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:funding_application_gp_project_costs)

      expect(assigns(:funding_application).project.errors.empty?).to eq(true)
      expect(assigns(:funding_application).project.project_costs.first.errors.empty?)
          .to eq(true)

      expect(assigns(:funding_application).project.project_costs.first.cost_type).to eq("new_staff")
      expect(assigns(:funding_application).project.project_costs.first.description).to eq("Test")
      expect(assigns(:funding_application).project.project_costs.first.amount).to eq(1000)

    end

  end

  describe "PUT #validate_and_redirect" do

    it "should re-render the page if there are no project costs" do

      expect(subject).to \
        receive(:log_errors).with(funding_application.project)

      put :validate_and_redirect,
          params: { application_id: funding_application.id }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)

      expect(assigns(:funding_application).project.errors.empty?).to eq(false)
      expect(assigns(:funding_application).project.errors.messages[:project_costs][0])
          .to eq(I18n.t("activerecord.errors.models.project.attributes.project_costs.blank"))

    end

    it "should successfully redirect if there are project costs" do

      create(
          :project_cost,
          project_id: funding_application.project.id,
          cost_type: "new_staff",
          description: "Test",
          amount: 500
      )

      put :validate_and_redirect,
          params: { application_id: funding_application.id }

      expect(response).to have_http_status(:redirect)
      expect(response)
          .to redirect_to(:funding_application_gp_project_are_you_getting_cash_contributions)

      expect(assigns(:funding_application).project.errors.empty?).to eq(true)

    end

  end

  describe "DELETE #delete" do

    it "should redirect to root for an invalid project" do

      delete :delete,
             params: {
                 application_id: "invalid",
                 project_cost_id: "invalid"
             }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:root)

    end

    it "should fail to find an invalid cost and redirect back" do

      expect {
        delete :delete,
               params: {
                application_id: funding_application.id,
                   project_cost_id: "invalid"
               }
      }.to raise_error(ActiveRecord::RecordNotFound)

    end

    it "should delete a valid project_cost and redirect back" do

      cost = create(
          :project_cost,
          project_id: funding_application.project.id,
          cost_type: "new_staff",
          description: "Test",
          amount: 500
      )

      allow(Rails.logger).to receive(:info)
      expect(Rails.logger).to receive(:info).ordered
      expect(Rails.logger)
          .to receive(:info).at_least(:once)
                  .with("Deleting cost ID: " \
                        "#{cost.id}")

      expect {
        delete :delete,
               params: {
                application_id: funding_application.id,
                   project_cost_id: cost.id
               }
      }.to change(funding_application.project.project_costs, :count).by(-1)

      expect(response).to have_http_status(:redirect)
      expect(response)
          .to redirect_to(:funding_application_gp_project_costs)

    end

  end

end
