class FundingApplication::LegalAgreements::ApplicantIsSignatoryController < ApplicationController
  include FundingApplicationContext
  include FundingApplicationHelper

  def show
    
    @funding_application.applicant_role = 
      @funding_application.legal_signatories.first&.role if 
        applicant_is_legal_sig?

  end

  def update

    @funding_application.applicant_is_legal_sig = 
      params[:funding_application].nil? ? nil : 
        params[:funding_application][:applicant_is_legal_sig]

    @funding_application.applicant_role = 
      params[:funding_application].nil? ? nil : 
        params[:funding_application][:applicant_role]

   
    @funding_application.validate_applicant_is_legal_sig = true
    
    if @funding_application.applicant_is_legal_sig == "true"
       @funding_application.validate_applicant_role = true 
    end

    logger.info "Validating in ApplicantIsSignatory for " \
      "funding_application ID: #{@funding_application.id}"

    if @funding_application.valid?
      if @funding_application.applicant_is_legal_sig == "true"

        if @funding_application.legal_signatories.first.present?

          sig = @funding_application.legal_signatories.first

          populate_signatory(
            sig,
            current_user.name,
            current_user.email,
            @funding_application.applicant_role
          )

          sig.save!

          logger.info "ApplicantIsSignatory saved new details for " \
            "an existing first signatory, id: #{sig.id} for " \
              "funding_application ID: #{@funding_application.id}"

        else

          # Otherwise build new sig, and save at application level
          @funding_application.legal_signatories.build

          populate_signatory(
            @funding_application.legal_signatories.first,
            current_user.name,
            current_user.email,
            @funding_application.applicant_role
          )

          @funding_application.save!

          logger.info "ApplicantIsSignatory saved details for " \
          "a newly build first signatory, id: " \
            " #{@funding_application.legal_signatories.first.id} for " \
              "funding_application ID: #{@funding_application.id}"
          
        end
        
        redirect_to :funding_application_second_signatory

      else
        redirect_to :funding_application_both_signatories

      end

     else
      render :show
     end
  end

  # simply populates a passed signatory with the other attributes
  # in own method to reduce duplication.
  #
  # @param [LegalSignatory] signatory An instance of an LegalSignatory
  # @param [String] name
  # @param [String] email
  # @param [String] role The role that a signatory has in the organisation
  #
  def populate_signatory(signatory, name, email, role)
    signatory.name = name
    signatory.email_address = email
    signatory.role = role
  end

  # Assigns a bool to applicant_is_legal_sig if the first legal
  # signatory is present and the email and name match the current user.
  # in own method to reduce duplication.
  #
  # Returns true if the signatory is present and name.email match
  # Returns false if signatory is present but name/email mismatch
  # Returns nil if the signatory is not present
  #
  # @return [Boolean] true if sig present and details match
  def applicant_is_legal_sig?()

    @funding_application.applicant_is_legal_sig = nil

    if @funding_application.legal_signatories.first.present?

      sig = @funding_application.legal_signatories.first

      @funding_application.applicant_is_legal_sig = 
        sig&.email_address&.strip&.upcase == current_user.email.strip&.upcase &&
            sig&.name.strip&.upcase == current_user.name.strip&.upcase
    end

    @funding_application.applicant_is_legal_sig

  end

end
