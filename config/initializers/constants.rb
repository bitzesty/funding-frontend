Rails.application.reloader.to_prepare do

  Rails.env.test? ? \

    SALESFORCE_URL_BASE = "" : \

      SALESFORCE_URL_BASE = SalesforceApi::SalesforceApiClient.new.get_salesforce_url

end