require 'rails_helper'

RSpec.describe ApplicationToSalesforceJob, type: :job do

  before(:each) do
    stub_request(:post, "https://test.salesforce.com/services/oauth2/token")
        .to_return(
            status: 200,
            body: '{"instance_url":"https://example.salesforce.com/"}'
        )

    user = build(:user)
    user.organisations.append(
        build(:organisation)
    )
    funding_application = create(
        :funding_application,
        organisation: user.organisations.first
    )

    @project = funding_application.project
    
    @project.user = user

  end

  it 'throws exception given error response from Salesforce' do

    stub_request(
        :post,
        "https://example.salesforce.com/services/apexrest/PortalData"
    ).to_return(
        status: 200,
        body: '{"statusCode":"401","status":"Failed","projectRefNumber":null,' \
              '"ProjectCostRefID":null,"Costs":null,"Costheading":null,' \
              '"caseNumber":null,"caseId":null,"accountId":null}'
    )

    expect { ApplicationToSalesforceJob.perform_now(@project) }
        .to raise_error(ApplicationToSalesforceJob::SalesforceApexError)

  end

  it "updates the database when run successfully" do

    stub_request(
        :post,
        "https://example.salesforce.com/services/apexrest/PortalData"
    ).to_return(
        status: 200,
        body: {
            statusCode: "200",
            status: "Success",
            projectRefNumber: "NS-19-01498",
            ProjectCostRefID: nil,
            Costs: nil,
            Costheading: nil,
            caseNumber: "00001498",
            caseId: "5002500000BFRUiAAP",
            accountId: "0012500001I6ImfAAF"
        }.to_json
    )

    ApplicationToSalesforceJob.perform_now(@project)

    expect(@project.funding_application.project_reference_number).to eq("NS-19-01498")
    expect(@project.funding_application.salesforce_case_id).to eq("5002500000BFRUiAAP")
    expect(@project.user.organisations.first.salesforce_account_id)
        .to eq("0012500001I6ImfAAF")
    expect(@project.funding_application.salesforce_case_number).to eq("00001498")

  end

end
