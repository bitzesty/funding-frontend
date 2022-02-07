class FundingApplication::LegalAgreements::BothSignatoriesController < ApplicationController
  include FundingApplicationContext
  include FundingApplicationHelper
  include ObjectErrorsLogger
  include LegalAgreementsHelper

  def show

    # may be more consistent journey to clear the sig fields before showing
    @funding_application.legal_signatories.build unless
      @funding_application.legal_signatories.first.present?
    @funding_application.legal_signatories.build unless
      @funding_application.legal_signatories.second.present?

  end

  def update

    logger.info "Validating legal signatories for funding application ID: " \
      "#{@funding_application.id}"

    @funding_application.validate_legal_signatories = true
    @funding_application.validate_legal_signatories_email_uniqueness = true

    @funding_application.update(funding_application_params)

    if @funding_application.valid?

      logger.info "Finished both_signatories_controller.rb model update for " \
        "funding_application ID: #{@funding_application.id}"

      upload_signatories_and_evidence_to_sf(@funding_application)
      
      @funding_application.legal_signatories.each do |legal_signatory|  
        send_legal_signatory_link_emails(@funding_application, legal_signatory)
      end

      @funding_application.update(
        agreement_submitted_on: DateTime.now
        
      )

      logger.info "both_signatories_controller update complete for " \
        "funding_application ID: #{@funding_application.id}"

      redirect_to :funding_application_awaiting_signatories

    else

      logger.info "Validation failed for one or more legal " \
        "signatory updates for funding_application ID: " \
          "#{@funding_application.id}"

      log_errors(@funding_application)

      render :show

    end

  end

  private

  def funding_application_params
    params.require(:funding_application).permit(
      legal_signatories_attributes: [
        :id,
        :name,
        :email_address,
        :role
      ]
    )
  end

end
