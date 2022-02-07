class SignatoryEmailValidator < ActiveModel::Validator

  def validate(record)
    
    if record.legal_signatories.first.email_address&.strip&.upcase == record.legal_signatories.second&.email_address&.strip&.upcase
      record.errors.add(
        :signatory_emails_unique,
         I18n.t('agreement.both_signatories.signatory_emails_unique_error')
      )
    end
        
  end

end
