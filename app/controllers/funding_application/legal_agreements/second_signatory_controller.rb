class FundingApplication::LegalAgreements::SecondSignatoryController < ApplicationController
  include FundingApplicationContext
  include FundingApplicationHelper

  def show
    initialize_second_sig()
  end

  # Issue in this code in that an applicant can get to next page, return, then
  # add an email that matches the applicant - then post again.
  # This is because the @funding_application.valid? reads from pg and is true
  # once any valid email is in.
  # Experimented with updating 
  # @funding_application.funding_applications_legal_sigs.second.legal_signatory. \
  #   update(params.require(:legal_signatory).permit(:name, :role, :email_address,))
  # Which means the update occurs from the funding_applications and up through
  # it associations, but has knock-ons - see needs more work.

  def update

    initialize_second_sig()

    populate_signatory(
      @second_sig,
      params
    )
    
    
    @funding_application.validate_legal_signatories_email_uniqueness = true

    logger.info "Validating in SecondSignatoryController for " \
      "funding_application ID: #{@funding_application.id}"

    if @funding_application.valid? && @second_sig.valid?
      # Call to @funding_application is needed for new legal_signatory instance
      # and funding_application_legals_sigs association rows.
      # Call to @second_sig is needed for existing legal_signatory instance updates
      # Could be refactored to make calls dependant on scanario to improve efficiency 
      @funding_application.save!
      @second_sig.save

      logger.info "SecondSignatoryController saved details for " \
        "second signatory, id: #{@second_sig.id} and for " \
          "funding_application ID: #{@funding_application.id}"

      redirect_to :funding_application_terms_and_conditions
    else
      render :show
      initialize_second_sig()
    end

  end

  private

  def populate_signatory(signatory, params)   
    if params[:legal_signatory].present?
      signatory.name = params[:legal_signatory][:name] 
      signatory.email_address = params[:legal_signatory][:email_address]
      signatory.role = params[:legal_signatory][:role]
    end

  end

  def initialize_second_sig()

    @second_sig = @funding_application.legal_signatories.second
 
    if !@second_sig.present?
      # Build second sig and associations with 'build'
      @second_sig = @funding_application.legal_signatories.build
    end

  end

end
