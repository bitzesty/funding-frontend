class PaymentRequest < ApplicationRecord

  has_many :funding_applications_pay_reqs, inverse_of: :payment_request
  has_many :funding_applications, through: :funding_applications_pay_reqs

  has_many :payment_requests_spends, inverse_of: :payment_request
  has_many :spends, through: :payment_requests_spends

  attr_accessor :higher_spend
  attr_accessor :lower_spend
  attr_accessor :no_update
  attr_accessor :validate_spend_journeys_to_do

  validate do

    validate_spend_journeys_to_do_presence if validate_spend_journeys_to_do

  end

  def validate_spend_journeys_to_do_presence

    if higher_spend == 'false' && \
      lower_spend == 'false' && \
        no_update == 'false'

      errors.add(
        :spend_journeys_to_do,
        I18n.t(
          "activerecord.errors.models.payment_request." \
            "attributes.spend_journeys_to_do.blank")
      )

    end

    if no_update == 'true' && \
      (lower_spend == 'true' || \
        higher_spend == 'true')

      errors.add(
        :spend_journeys_to_do,
        I18n.t(
          "activerecord.errors.models.payment_request." \
            "attributes.spend_journeys_to_do.choose")
      )

    end

  end

end
