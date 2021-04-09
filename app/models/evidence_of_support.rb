class EvidenceOfSupport < ApplicationRecord
  include GenericValidator

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'evidence_of_support'

  self.implicit_order_column = 'created_at'

  belongs_to :project, optional: true

  has_many :funding_applications_evidence, inverse_of: :evidence_of_support
  has_many :funding_applications, through: :funding_applications_evidence

  has_one_attached :evidence_of_support_files

  validates :description, presence: true

  validate do

    validate_file_attached(
        :evidence_of_support_files,
        "Add an evidence of support file"
    )

    validate_length(
        :description,
        50,
        I18n.t('activerecord.errors.models.evidence_of_support.attributes.description.too_long')
    )

  end

end

