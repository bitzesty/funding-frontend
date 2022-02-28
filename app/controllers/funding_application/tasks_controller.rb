class FundingApplication::TasksController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger
  include DashboardHelper
  include DashboardHelper
  include FundingApplicationHelper

  def show

    set_award_type(@funding_application)

    set_instance_variables(@funding_application)

    if @legal_agreement_in_place && @funding_application.is_100_to_250k? && \
      Flipper.enabled?(:progress_and_spend_enabled)

      @funding_application.update(status: :payment_can_start)
      logger.info("legal agreement in place for funding_application #{@funding_application.id}")

      redirect_to funding_application_progress_and_spend_start_path(
        application_id: @funding_application.id
      )

    end

  end

  # Used to determine if the agree to terms and conditions
  # link should be shown at all.
  # Do not show when two signatories shown that are not the applicant.
  #
  # Returns true if first applicant not completed yet
  # Returns true if the applicant is a signatory
  #
  # @param funding_application [FundingApplication] An instance of
  #                                                 FundingApplication
  # @param applicant [User] An instance of User
  # @return [Boolean] false if two sigs submitted who weren't applicant
  def show_agree_terms_conditions_link?(funding_application, applicant)
    
    (
      funding_application.legal_signatories.first.nil? || \
        is_applicant_legal_signatory?(
          funding_application,
          applicant)
    )
      
  end

  private

  # Method used to orchestrate setting instance variables which are
  # referenced in the corresponding view
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  def set_instance_variables(funding_application)

    @not_awarded = !awarded(
      funding_application,
      get_salesforce_api_instance()
    )

    @has_agreed_to_grant =
      funding_application.agreement&.grant_agreed_at.present?

    @has_not_agreed_to_terms =
      funding_application.agreement&.terms_agreed_at.nil?

    @show_agree_terms_conditions_link = show_agree_terms_conditions_link?(
      @funding_application,
      current_user
    )

    # Todo: legal_agreement_in_place? temporarily return false if
    # the award is >100k.  To prevent this journey starting.
    @legal_agreement_in_place = legal_agreement_in_place?(
      funding_application,
      get_salesforce_api_instance()
    )

    # Show if agreements.terms_agreed_at is not null
    # AND the actual agreements table needs to have copies stored.
    # Which isn't the case for older applications.
    @view_signed_agreement =
      @funding_application&.agreement&.terms_agreed_at.present? &&
        @funding_application&.agreement&.project_details_html.present? &&
          @funding_application&.agreement&.terms_html.present?

    @first_payment_not_started =
      funding_application&.payment_requests&.first.nil?

    @first_payment_in_progress =
      funding_application&.payment_requests&.first.present? &&
      funding_application&.payment_requests&.first&.submitted_on.nil?

    @first_payment_completed =
      funding_application&.payment_requests&.first&.submitted_on.present?

    set_status_tags(funding_application)

  end

  # Method used to orchestrate setting instance variables which are
  # referenced in the corresponding view
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  def set_status_tags(funding_application)

    set_agreement_status_tag(funding_application)
    set_terms_status_tag(funding_application)

  end

  # Method used to set @agreement_status_tag_label and
  # @agreement_status_tag_colour instance variables based on the current
  # status of a FundingApplication's legal agreement
  #
  # A legal agreement is considered to be 'Not started' if a
  # FundingApplication does not have an associated Agreement
  #
  # A legal agreement is considered to be 'In process' if a
  # FundingApplication has an associated Agreement which does not have a
  # populated grant_agreed_at attribute
  #
  # A legal agreement is considered to be complete if a
  # FundingApplication has an associated Agreement which has a populated
  # grant_agreed_at attribute
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  def set_agreement_status_tag(funding_application)
    case
    when funding_application.agreement.nil?
      @agreement_status_tag_label = I18n.t('generic.not_started')
      @agreement_status_tag_colour = 'grey'
    when funding_application.agreement.present? &&
        funding_application.agreement.grant_agreed_at.nil?
      @agreement_status_tag_label = I18n.t('generic.in_progress')
      @agreement_status_tag_colour = 'blue'
    when funding_application.agreement.present? &&
        funding_application.agreement.grant_agreed_at.present?
      @agreement_status_tag_label = I18n.t('generic.submitted')
      @agreement_status_tag_colour = 'grey'
    end

  end

  # Method used to set @terms_status_tag_label and @terms_status_tag_colour
  # instance variables based on the current status of a FundingApplication's
  # legal agreement
  #
  # Terms and conditions for a legal agreement are considered to be
  # 'Cannot yet start' if either a FundingApplication does not have an
  # associated Agreement, or if the associated Agreement does not have a
  # populated grant_agreed_at attribute
  #
  # Terms and conditions for a legal agreement are considered to be
  # 'In progress' if a FundingApplication has an associated Agreement
  # which has a populated grant_agreed_at attribute
  #
  # Terms and conditions for a legal agreement are considered to be
  # 'Completed' if a FundingApplication's associated Agreement has
  # an associated FundingApplicationAgreement record which has a
  # populated  attribute
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  #
  # Todo. This is overcomplicated. Ruby has no fallthroughs and 
  # executes in order.  So could use safe operators to make the 
  # when statements one line, and execute in revesre order so
  # targeting the latest agreement statuses first.
  def set_terms_status_tag(funding_application)

    case
    when @funding_application.agreement.nil? ||
        funding_application.agreement.present? &&
        funding_application.agreement.grant_agreed_at.nil?
      @terms_status_tag_label = I18n.t('generic.cannot_start')
      @terms_status_tag_colour = 'grey'
    when funding_application.agreement.present? &&
        funding_application.agreement.grant_agreed_at.present? &&
        funding_application.agreement.terms_agreed_at.nil?
      @terms_status_tag_label = I18n.t('generic.in_progress')
      @terms_status_tag_colour = 'blue'
    when funding_application.agreement.terms_agreed_at.present?
      @terms_status_tag_label = I18n.t('generic.submitted')
      @terms_status_tag_colour = 'grey'
    end

  end

end
