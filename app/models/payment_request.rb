class PaymentRequest < ApplicationRecord

  has_many :funding_applications_pay_reqs, inverse_of: :payment_request
  has_many :funding_applications, through: :funding_applications_pay_reqs

  has_many :low_spend, dependent: :destroy

  accepts_nested_attributes_for :low_spend

  attr_accessor :higher_spend
  attr_accessor :lower_spend
  attr_accessor :no_update
  attr_accessor :validate_spend_journeys_to_do
  
  attr_accessor :lower_spend_chosen
  attr_accessor :validate_lower_spend_chosen

  validates :lower_spend_chosen, presence: true, if: :validate_lower_spend_chosen?

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

  def validate_lower_spend_chosen?
    validate_lower_spend_chosen == true
  end

end
