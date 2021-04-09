class NonCashContribution < ApplicationRecord
  include ActiveModel::Validations
  include GenericValidator

  self.implicit_order_column = 'created_at'

  belongs_to :project, optional: true

  has_many :funding_applications_nccs, inverse_of: :non_cash_contributions
  has_many :funding_applications, through: :funding_applications_nccs

  validates :description, presence: true
  validates :amount, numericality: {
      only_integer: true,
      greater_than: 0
  }

  # It's possible that we have existing non_cash_contribution records with
  # description attributes greater than 50 characters. By specifying to run
  # this validation only on creation of a non_cash_contribution object,
  # we ensure that Rails doesn't attempt to validate any existing
  # non_cash_contribution records associated to the same project
  # or funding_application
  validate on: :create do

    validate_length(
      :description,
      50,
      I18n.t(
        'activerecord.errors.models.non_cash_contribution.attributes' \
          '.description.too_long',
        word_count: 50
      )
    )

  end

end
