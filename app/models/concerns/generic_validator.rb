module GenericValidator
  extend ActiveSupport::Concern

  def validate_file_attached(field, error_msg)
    unless self.public_send(field).attached?
      errors.add(field, error_msg)
    end
  end

  def validate_length(field, max_length, error_msg)

    word_count = self.public_send(field)&.split(' ')&.count

    logger.debug "#{field} word count is #{word_count}"

    if word_count && word_count > max_length
      self.errors.add(field, error_msg)
    end

  end

  def validate_date(field, day, month, year)

    if !Date.valid_date? date_year.to_i, date_month.to_i, date_day.to_i
      errors.add(
          field,
          I18n.t("activerecord.errors.models.statutory_permission_or_" \
            "licence.attributes.licence_date.invalid")
      )
    end

  end

end
