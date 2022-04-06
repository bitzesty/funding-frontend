class FundingApplication::ProgressAndSpend::ProgressUpdate::\
  CashContribution::CashContributionSelectController < ApplicationController
  include FundingApplicationContext
  include FundingApplicationHelper
  include ProgressAndSpendHelper

  def show()

    populate_form_attributes_from_salesforce

  end 

  def update()

    progress_update.validate_cash_contribution_selected = true

    rp = required_params(params)

    # amend answers_json to store which answers were selected for update
    rp.each do |record|

      # each param is an array, [0] value is id,  [1] is whether selected.
      if progress_update.answers_json['cash_contribution']['records'].has_key?(record[0])
        progress_update.answers_json['cash_contribution']['records'][record[0]]['selected_for_update'] = record[1]

        # if anything selected during the loop, cash_contribution_selected becomes true.
        progress_update.cash_contribution_selected = true if record[1] == "true"

        progress_update.save

      end

    end

    unless progress_update.errors.any?
    
      set_award_type(@funding_application)

      medium_cash_contribution_redirector(progress_update.answers_json) if \
        @funding_application.is_100_to_250k?

    else
      
      populate_form_attributes_from_salesforce
      render :show

    end
    
  end

  # Returns an instance of ProgressUpdate for current context
  # @return [ProgressUpdate]
  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end

  # Returns array of cash contribution descriptions for a medium application
  # that is < £250001.
  # Uses Description_for_cash_contributions__c for the array.
  # 
  # Large applications will require a new function that
  # returns 'source of funding' for display to the applicant
  #
  # @param [<Restforce::SObject] sf_cash_contributions Collection from SF
  # @return [Array] cash_contributions_descs Array of hashes
  def medium_cash_contribution_descriptions(sf_cash_contributions)

    cash_contribution_descs = []

    sf_cash_contributions.each do |cc|
      cash_contribution_descs.push(
        {
          id: cc.Id, 
          description: cc.Description_for_cash_contributions__c
        }
      )

    end

    cash_contribution_descs

  end

  # Updates answers_json so that it can be the basis for orchestrating the
  # cash contributions updates journey for arrears payments.
  # Each cash contribution in the ccs_from_salesforce collection is used
  # to create new json information within ['records'] of answers_json
  #
  # @param [<Restforce::SObject] ccs_from_salesforce Collection of cash
  #                                              contributions from salesforce
  # @param [String] answers_json JSONB with arrears journey info
  def update_answers_json_from_medium_salesforce_collection(
    ccs_from_salesforce, answers_json)

    ccs_from_salesforce.each do |cc|

      answers_json['cash_contribution']['records'][cc.Id] = {
        'selected_for_update' => false,
        'update_finished' => false
      }

    end

    progress_update.answers_json = answers_json
    progress_update.save

  end

  # updates json with a new key value pair
  # In this case, whether has_cash_contribution_update is selected.
  # @params [jsonb] answers_json Json containing journey answers
  # @params [Boolean] answer Either true or false
  def update_json(answers_json, answer)
    answers_json['cash_contribution']['has_cash_contribution_update'] = answer
    progress_update.answers_json = answers_json
    progress_update.save
  end

  # Returns the required params.  Nothing permitted, as the id is dynamic
  # Will use Id to query answers_json which will enforce security.
  #
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def required_params(params)
    params.require(:progress_update)
  end


  # Gets the form information from Salesforce and populates these variable for
  # use on the form:
  # @cc_desc - a collection of cash contribution descriptions
  # @first_form_element - if nothing is selected, href goes to this id
  #
  # Also initialises answers_json with the required attributes.
  #
  # May need refactoring if slow - it's called on every show.
  #
  # Consider passing in pointers if tricky to unit test.
  #
  def populate_form_attributes_from_salesforce

    set_award_type(@funding_application)

    if @funding_application.is_100_to_250k?

      ccs_from_salesforce = salesforce_medium_cash_contributions(
        @funding_application
      )

      @cc_desc = medium_cash_contribution_descriptions(
        ccs_from_salesforce
      )

      update_answers_json_from_medium_salesforce_collection(
        ccs_from_salesforce,
        progress_update.answers_json
      )

    else

      @cc_desc = [] # Large to follow

    end

    # error link id, if the applicant selects nothing.
    @first_form_element = "progress_update_#{ccs_from_salesforce.first.Id}"

  end

end
