class SalesforceSpendingCostDeleteError < StandardError; end

class DeleteSpendingCostJob < ApplicationJob
  include SalesforceApiHelper
  queue_as :default
  retry_on SalesforceSpendingCostDeleteError 

  # Method to delete a Salesforce Spending_Costs__c using
  # Salesforce Id.
  #
  #
  # @param [string] spending_costs_id  ID of Spending_Costs__c
  def perform(spending_costs_id)

    initialise_client

    begin 

      Rails.logger.info(
        "Attempting to delete Spending_Costs__c Id #{spending_costs_id}"
      )

      @client.destroy('Spending_Costs__c', spending_costs_id)

      Rails.logger.info(
        "Finished deleting Spending_Costs__c Id #{spending_costs_id}"
      ) 

    rescue Exception => e

      Rails.logger.error("Spending Cost delete failed for Spending_Costs__c Id " \
        "#{spending_costs_id} with error #{e.message}")
      
      raise SalesforceFileDeleteError.new("Spending Cost delete failed for " \
        "Spending_Costs__c Id #{spending_costs_id} with error #{e.message}")
    end

  end

end
