class FundingApplication::TasksController < ApplicationController
  include FundingApplicationContext
  include ObjectErrorsLogger
  include DashboardHelper
  include DashboardHelper
  include FundingApplicationHelper

  GENERIC_TIMESTAMP = '0001-01-01 00:00:00.000000'

  def show

    set_instance_variables(@funding_application)

    if @legal_agreement_in_place && @funding_application.is_100_to_250k? && \
      Flipper.enabled?(:progress_and_spend_enabled)

      @funding_application.update(status: :payment_can_start)
      logger.info("legal agreement in place for funding_application #{@funding_application.id}")

      check_for_agreement_submitted_on(@funding_application)

      redirect_to funding_application_progress_and_spend_start_path(
        application_id: @funding_application.id
      )

    elsif @funding_application.dev_to_100k?
      salesforce_api_instance = get_salesforce_api_instance()
      @large_project_title = get_large_project_title(
        salesforce_api_instance, 
        @funding_application.salesforce_case_id
      )

    elsif Flipper.enabled?(:m1_40_payment) && \
      @funding_application.is_10_to_100k? && \
        first_50_percent_payment_completed?(@funding_application) && \
          !@funding_application.m1_40_payment_complete?
        
      @funding_application.update(status: :m1_40_payment_can_start)

      logger.debug("M1 40% payment started for funding_application"\
        "#{@funding_application.id}")

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

    salesforce_api_instance = get_salesforce_api_instance()

    @not_awarded = !awarded(
      funding_application,
      salesforce_api_instance
    )

    @has_agreed_to_grant =
      funding_application.agreement&.grant_agreed_at.present?

    @has_not_agreed_to_terms =
      funding_application.agreement&.terms_agreed_at.nil?

    @show_agree_terms_conditions_link = show_agree_terms_conditions_link?(
      @funding_application,
      current_user
    )

    submitted_and_agreement_in_place =
      funding_application.submitted_on.present? && \
        legal_agreement_in_place?(
          funding_application.salesforce_case_id,
          salesforce_api_instance
        )

    @legal_agreement_in_place = submitted_and_agreement_in_place

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

    # Not nil if a forty percent journey has been completed.
    @completed_arrears_journey =
      @funding_application&.completed_arrears_journeys&.first

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
  # This is disregarded if the application is dev_to_100k.  This is because
  # the agreement has been completed via permission to start. So we rely
  # on it being completed before getting to this point in the grantee's
  # journey.
  #
  # @param [FundingApplication] funding_application An instance of
  #                                                 FundingApplication
  def set_agreement_status_tag(funding_application)

    unless funding_application.dev_to_100k?

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

    else

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

  # Older legal agreements do not set
  # funding_application.agreement_submitted_on.
  # This causes them to fail the FundingApplicationContext check for
  # invalid_view_for_submitted_application when accessing arrears payments.
  #
  # This method is called when we have confirmed payment can start,
  # using Salesforce.  If it finds that no timestamp exists, it adds
  # a recognisable generic one, to allow the context check to pass.
  #
  # We could work out and enter a timestamp for when we think the last
  # signatory submitted their terms - but this is disingenuous. Better to
  # to use a clearly generic timestamp, that we can tie back to this function.
  #
  # We can monitor the number of potentially affected cases by running SQL
  # to count the number of potentially affected cases.
  #
  # This counts all medium applications where agreement_submitted_on
  # is incorrectly null:
  #
  # select count(*) from funding_applications where id in
  # (select distinct(funding_application_id) from agreements
  # where grant_agreed_at is not null and terms_agreed_at is not null)
  # and agreement_submitted_on is null and project_reference_number like 'NM%';
  #
  # This is crude and should be either amended or run at non-busy times.
  # Brings back 239 rows at the time of writing.  Some will not be medium
  # applications > 100K , and so the actual number in less.  Also use
  # funding_applicaions_pay_reqs table to see what applications have started
  # payments already.
  #
  # As more cases are completed with the new agreements process, the need for this
  # method will go.  Consider running SQL to see when the count is low enough.
  #
  def check_for_agreement_submitted_on(funding_application)

    if funding_application.agreement_submitted_on.nil?

      @funding_application.update(agreement_submitted_on: GENERIC_TIMESTAMP)

      Rails.logger.info("check_for_agreement_submitted_on found no timestamp for " \
        "funding application #{funding_application.id}. Inserted #{GENERIC_TIMESTAMP}")

    end

  end

end
