# Stores acknowledgements as JSON, example below.
#
# Storing as JSON grants flexibility, as these acknowledgements could be
# changed, added or removed.
#
# Only submit to Salesforce if 'no_update' is NOT selected.  Then only
# submit acknowledgements that were selected.
#
# If 'no_update' is selected, the JSON could be cleaned up, but there
# are currently no files associated - so significant storage savings in
# doing this.
#
# {
#   "media": {
#     "selected": "true",
#     "acknowledgement": "some med"
#   },
#   "signs": {
#     "selected": "false",
#     "acknowledgement": "s"
#   },
#   "events": {
#     "selected": "false",
#     "acknowledgement": ""
#   },
#   "online": {
#     "selected": "false",
#     "acknowledgement": ""
#   },
#   "no_update": {
#     "selected": "false",
#     "acknowledgement": null
#   },
#   "publications": {
#     "selected": "false",
#     "acknowledgement": ""
#   }
# }

class FundingApplication::ProgressAndSpend::ProgressUpdate::\
    FundingAcknowledgementController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()

    @funding_acknowledgement = get_funding_acknowledgement

  end

  def update()

    @funding_acknowledgement = get_funding_acknowledgement

    fp = fetch_params(params, @funding_acknowledgement.acknowledgements)

    if successfully_updated_acknowledgments?(@funding_acknowledgement, fp)

      redirect_to(
        funding_application_progress_and_spend_progress_update_check_outcome_answers_path(
          progress_update_id:  \
            @funding_application.arrears_journey_tracker.progress_update.id
        )
      )

    else

      render :show

    end

  end

  # Gets an instance of funding_acknowledgement
  # Checks to see if an instance exists, and returns if so.
  # otherwise builds an in memory instance and returns
  # @return [ProgressUpdateFundingAcknowledgement]
  def get_funding_acknowledgement

    progress_update =  @funding_application.arrears_journey_tracker.progress_update

    progress_update.progress_update_funding_acknowledgement.first.nil? ? \
      build_funding_acknowledgement : \
        progress_update.progress_update_funding_acknowledgement.first

  end

  # Builds a funding acknowledgement, initialises and assigns its
  # acknowledgmentrs attribute with a hash from calling
  # get_funding_acknowledgements_hash
  #
  # @return [FundingAcknowledgment] fa
  def build_funding_acknowledgement

    progress_update =  @funding_application.arrears_journey_tracker.progress_update
    fa = progress_update.progress_update_funding_acknowledgement.build
    fa.acknowledgements = get_funding_acknowledgements_hash

    fa

  end

  # Returns the fetched params.
  # We could hard code the permitted params here.  But have built an array
  # of permitted params from the passed Hash.  Saves duplicating these
  # values and future proofs if we ever want to get these from Salesforce
  #
  # @params [ActionController::Parameters] params A hash of params
  # @return [ActionController::Parameters] params A hash of filtered params
  def fetch_params(params, acknowledgements)

    permitted_params = []

    acknowledgements.each do |key, value|
      permitted_params << "#{key}_selected".to_sym
      permitted_params << "#{key}_acknowledgement".to_sym
    end

    permitted_params << :no_update_yet

    params.fetch(:progress_update_funding_acknowledgement).permit(
      permitted_params
    )
  
  end

  # Changes to funding acknowledgement types GO HERE
  # If the corresponding translations are added, then the
  # show, validation and update will follow.
  #
  # To preserve the order specified, modify the slice function
  # in the show.
  #
  # Gets a hash of the funding acknowledgement types
  # This could be retrieved from a table or from Salesforce, but
  # Neither of those things exist.  This is adequate.
  #
  # The hash key forms the last part of the translation used,
  # So consider this if making a change.
  # For example, a key called 'at_event' will use
  # the translation at:
  # progress_and_spend.progress_update.funding_acknowledgement.at_event
  # on /show.html.erb
  #
  # @return [Hash] funding_acknowledgements_hash A hash populated with 
  #          funding ackowledgements information that a user needs to complete.
  def get_funding_acknowledgements_hash

    funding_acknowledgements_hash = {}

    funding_acknowledgements_hash[:signs] =
      {acknowledgement: '', selected: nil}

    funding_acknowledgements_hash[:publications] =
      {acknowledgement: '', selected: nil}

    funding_acknowledgements_hash[:events] =
      {acknowledgement: '', selected: nil}

    funding_acknowledgements_hash[:online] =
      {acknowledgement: '', selected: nil}

    funding_acknowledgements_hash[:media] =
      {acknowledgement: '', selected: nil}

    funding_acknowledgements_hash[:no_update] =
      {acknowledgement: '', selected: nil}

    funding_acknowledgements_hash

  end

  # Assigns each param to the correct place in the acknowledgements hash
  # loops through the acknowledgements hash, finds the corresponding param
  # then updates with that data.
  #
  # Saves assuming validation correct
  #
  # @return [Boolean] result If valid and saved, then true else false
  def successfully_updated_acknowledgments?(funding_acknowledgement, fp)

    params_hash = fp.to_hash

    # loops through existing acknowledgements, and assigns from params.
    funding_acknowledgement.acknowledgements.each do |ack_key, ack_value|

      ack_value['selected'] = params_hash["#{ack_key}_selected"]
      ack_value['acknowledgement'] = params_hash["#{ack_key}_acknowledgement"]

    end

    funding_acknowledgement.no_update_yet = fp[:no_update_yet]

    if funding_acknowledgement.valid?

      funding_acknowledgement.save!

      result = true

    end

  end

end
