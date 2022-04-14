class ProgressUpdateOutcome < ApplicationRecord
  include GenericValidator

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'prgrss_updts_outcomes'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  attr_accessor :validate_progress_updates

  validate do

    validate_progress_updates_fields(self.progress_updates) \
      if validate_progress_updates?

  end


  def validate_progress_updates_fields(progress_update_json)

    progress_update_json.each do |key,value|

      logger.debug "progress_update_json #{key} value is #{value}"

      if value.strip.length < 1
        self.errors.add(
          key,
          I18n.t("activerecord.errors.models." \
            "progress_update_outcome.attributes.all.blank"))
      end

      word_count = value&.split(' ')&.count

      if word_count && word_count > 300
        self.errors.add(
          key,
          I18n.t("activerecord.errors.models." \
            "progress_update_outcome.attributes.all.too_long"))
      end

    end

  end

  def validate_progress_updates?
    validate_progress_updates == true
  end

end
