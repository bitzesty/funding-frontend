include SalesforceApi

Rails.env.test? ? \
  SALESFORCE_URL_BASE = "" : \
    SALESFORCE_URL_BASE = SalesforceApiClient.new.get_salesforce_url
