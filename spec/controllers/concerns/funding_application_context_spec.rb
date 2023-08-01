require "rails_helper"

RSpec.describe FundingApplicationContext do

  # To test our controller concerns, we use the concept of an anonymous
  # controller, which allows us to access RSpec methods and helpers.

  controller(ApplicationController) do
    include FundingApplicationContext

    # Our anonymous controller will need a route, and this route will need
    # to be able to hit a method, which we are defining here.
    def fake_action
      redirect_to("/url")
    end

  end

  before {
    routes.draw {
      # Here we are defining the route for our anonymous controller, and
      # directing it to the method we have created for our anonymous controller
      get 'fake_action/:application_id' => 'anonymous#fake_action'
    }
  }

  describe "set_funding_application failure scenario - invalid funding application" do
    login_user

    before {
      get :fake_action,
          params: {
              application_id: 100,
          }
    }

    it "should redirect to root if the funding application does not belong " \
       "to the current user" do

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:root)

    end

  end

  describe 'set_funding_application failure scenario - no project' do

    login_user

    let(:funding_application) {
      create(
        :funding_application,
        id: 'id',
        organisation_id: subject.current_user.organisations.first.id,
        project: nil,
        award_type: 3, 
        status: 0
      )
    }

    before {
      get :fake_action,
          params: {
              application_id: funding_application.id
          }
    }

    it "should redirect to root if the funding application belonging to the current user " \
       "does not have an associated project" do

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:root)

    end

  end

  describe "set_funding_application failure scenario - no funding application status " \
    "(simulating existing projects, prior status being added)" do

    login_user

    let(:funding_application) {
      create(
        :funding_application,
        id: 'id',
        organisation_id: subject.current_user.organisations.first.id,
        project: nil,
        award_type: 3, 
        status: nil
      )
    }

    before {
      get :fake_action,
          params: {
              application_id: funding_application.id
          }
    }

    it "should redirect to root if the funding application belonging to the current user " \
       "does not have an associated project or status set" do

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:root)

    end

  end

  describe "set_funding_application failure scenario - submitted funding application" do
    login_user

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

    let(:funding_application) {
      create(
        :funding_application,
        id: "id",
        organisation_id: subject.current_user.organisations.first.id,
        submitted_on: Date.new
      )
    }

    before {
      get :fake_action,
          params: {
              application_id: funding_application.id
          }
    }

    it "should redirect to root if the funding application belonging to the current user " \
       "has been submitted" do

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(:root)

    end

  end

  describe "set_funding_application success scenario" do
    login_user

    let(:legal_signatory) {
      create(
        :legal_signatory,
        id: '1',
        name: 'Joe Bloggs',
        email_address: 'joe@bloggs.com',
        phone_number: '07000000000'
      )
    }

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

    let(:funding_application) {
      create(
        :funding_application,
        id: "id",
        organisation_id: subject.current_user.organisations.first.id,
        submitted_on: Date.new
      )
    }

    before {
      get :fake_action,
          params: {
              application_id: funding_application.id
          }
    }

    it "should assign the @funding_application instance variable if the funding_application belongs " \
        "to the current user and has not been submitted" do

      expect(assigns(:funding_application)).to eq(funding_application)

    end

  end
  
end  

  # Further work needed on tests to assert if before_action: :authenticate_user! is being called. leaving comments for reference. 

#   describe "set_funding_application failure scenario - invalid funding application" do
#    login_user

#    let(:legal_signatory) {
#     create(
#       :legal_signatory,
#       id: '1',
#       name: 'Joe Bloggs',
#       email_address: 'joe@bloggs.com',
#       phone_number: '07000000000'
#     )
#   }

#   before do

#     subject.current_user.organisations.first.update(
#       name: 'Test Organisation',
#       line1: '10 Downing Street',
#       line2: 'Westminster',
#       townCity: 'London',
#       county: 'London',
#       postcode: 'SW1A 2AA',
#       org_type: 1
#     )
    
#   end

#   let(:funding_application) {
#     create(
#       :funding_application,
#       id: "id",
#       organisation_id: subject.current_user.organisations.first.id,
#       submitted_on: Date.new
#     )
#   }

#   before {
#     get :fake_action,
#         params: {
#             application_id: funding_application.id
#         }
#   }

#     sign_out_user
#     it "should redirect to root if the current user is not logged in " do
#       expect(response).to have_http_status(:redirect)
#       expect(response).to redirect_to(:root)
#     end

#   end

#   # describe "authenticate_user! should be called before set_funding_application" do
  
    
#   #   it "should authenticate user and redirect to root " \
#   # end  
# end

# # we want to assert that authenticate_user! is called before set_funding_application
