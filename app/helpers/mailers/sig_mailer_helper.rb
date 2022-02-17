# Orchestrates languages for signatory emails.
# Sits between controllers and NotifyMailer.
# Helper that decides what language a template should be sent in.
# For emails that are sent to legal signatories


module Mailers::SigMailerHelper

  include Mailers::CommonMailerHelper


  # Determines the appropriate language and send the correct template
  #
  # @param [String] recipient_email_address The email address to send this
  #                                         email to
  # @param [String] funding_application_id A UUID for a FundingApplication
  # @param [String] agreement_link A unique link which will allow a
  #                                LegalSignatory access to the legal agreement
  #                                journey
  # @param [String] project_title The title of a project
  # @param [String] project_reference_number A unique NLHF-assigned reference
  #                                          number for a project
  # @param [String] organisation_name The name of an organisation
  def send_mail_with_signatory_link(
    recipient_email_address,
    funding_application_id,
    agreement_link,
    project_title,
    project_reference_number,
    organisation_name, 
    fao_email
  )
    
    deliver_email_with_signatory_link(
      recipient_email_address,
      funding_application_id,
      agreement_link,
      project_title,
      project_reference_number,
      organisation_name, 
      fao_email,
      '9ba83d4a-e445-4c12-9f03-545bcbca4878'
    ) if send_english_mails?

    deliver_email_with_signatory_link(
      recipient_email_address,
      funding_application_id,
      agreement_link,
      project_title,
      project_reference_number,
      organisation_name, 
      fao_email,
      'ba8de19e-eb15-46e9-a415-71b5167fb170'
    ) if send_welsh_mails?

    deliver_email_with_signatory_link(
      recipient_email_address,
      funding_application_id,
      agreement_link,
      project_title,
      project_reference_number,
      organisation_name, 
      fao_email,
      '3290db41-b688-4ea1-b48d-c1258adbd30c'
    ) if send_bilingual_mails?

    log_mails_sent(__method__.to_s)

  end

  def deliver_email_with_signatory_link(
    recipient_email_address,
    funding_application_id,
    agreement_link,
    project_title,
    project_reference_number,
    organisation_name, 
    fao_email,
    template_id
  )

    NotifyMailer.email_with_signatory_link(
      recipient_email_address,
      funding_application_id,
      agreement_link,
      project_title,
      project_reference_number,
      organisation_name, 
      fao_email,
      template_id
    ).deliver_later()

  end
  
end
