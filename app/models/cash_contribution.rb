class CashContribution < ApplicationRecord
  include GenericValidator

  self.implicit_order_column = 'created_at'

  belongs_to :project, optional: true

  has_many :funding_applications_ccs, inverse_of: :cash_contributions
  has_many :funding_applications, through: :funding_applications_ccs

  has_one_attached :cash_contribution_evidence_files

  validates :description, presence: true
  validates :amount, numericality: {
      only_integer: true,
      greater_than: 0
  }
  validates_inclusion_of :secured, in: ["yes_with_evidence", "no", "x_not_sure", "yes_no_evidence_yet"]

  validate do

    validate_file_attached(
        :cash_contribution_evidence_files,
        I18n.t("activerecord.errors.models.cash_contribution.attributes.cash_contribution_evidence_files.inclusion")
    ) if self[:secured] == "yes_with_evidence"

    validate_length(
        :description,
        50,
        I18n.t("activerecord.errors.models.cash_contribution.attributes.description.too_long")
    )

  end

  enum secured: {
    yes_with_evidence: 0,
    no: 1,
    # added x_ prefix to avoid conflict with auto generated negative scopes.
    x_not_sure: 2,
    yes_no_evidence_yet: 3
  }

end
