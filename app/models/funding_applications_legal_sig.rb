class FundingApplicationsLegalSig < ApplicationRecord
  include ActiveModel::Validations
  include GenericValidator

  belongs_to :funding_application
  belongs_to :legal_signatory

  has_one_attached :signed_terms_and_conditions

  attr_accessor :validate_signed_terms_and_conditions

  def validate_signed_terms_and_conditions?
    validate_signed_terms_and_conditions == true
  end

  validate do
    validate_file_attached(
        :signed_terms_and_conditions,
        I18n.t(
          'activerecord.errors.models.funding_application.attributes' \
          '.signed_terms_and_conditions.inclusion'
        )
    ) if validate_signed_terms_and_conditions?
  end

end
