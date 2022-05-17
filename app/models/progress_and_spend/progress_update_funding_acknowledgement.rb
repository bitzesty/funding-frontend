class ProgressUpdateFundingAcknowledgement < ApplicationRecord
  include GenericValidator

  self.table_name = 'prgrss_updts_fndng_acknwldgmnts'

  self.implicit_order_column = 'created_at'

  belongs_to :progress_update, optional: true

  attr_accessor :no_update_yet

  validate do

    validate_selected(self.acknowledgements)
    validate_acknowledgements(self.acknowledgements, 100)

  end


  # loops through acknowledgements json and:
  # 1 - adds a type error if items is selected but acknowledgement is empty
  # 2 - adds a typr error if acknowledgment over word count
  #
  # @params [String] acknowledgements_json
  # @params [Integer] max_words
  def validate_acknowledgements(acknowledgements_json, max_words)

    acknowledgements_json.each do |ack_type, ack_value|

      logger.debug "type is #{ack_type} ack json is #{ack_value}"

      unless ack_type == 'no_update'

        if ack_value['selected'] == 'true' && \
            ack_value['acknowledgement'].strip.length < 1

          self.errors.add(
            ack_type,
            I18n.t("activerecord.errors.models." \
              "progress_update_funding_acknowledgement.attributes.all.blank"))
        end

        word_count = ack_value['acknowledgement']&.split(' ')&.count

        if word_count && word_count > max_words
          self.errors.add(
            ack_type,
            I18n.t(
              "activerecord.errors.models." \
                "progress_update_funding_acknowledgement.attributes.all.too_long",
              word_count: 100
            )
          )
        end

      end

    end

  end

  # No error if either the "I don't have an update" is
  # selected or an update is chosen.
  # Error added if an update and "I don't have an update" are
  # chosen.  Or if nothing is chosen.
  #
  # @params [String] acknowledgements_json
  def validate_selected(acknowledgements_json)

    one_or_more_checkbox_selected = false

    acknowledgements_json.each do |ack_key, ack_value|

      unless ack_key == 'no_update'

        if ack_value['selected'] == 'true'
          one_or_more_checkbox_selected = true
          break
        end

      end

    end

    if one_or_more_checkbox_selected != \
        (acknowledgements_json['no_update']['selected'] == 'true')
    else
      self.errors.add(
        :no_update_yet,
        I18n.t("activerecord.errors.models." \
          "progress_update_funding_acknowledgement." \
            "attributes.no_update.selections")
      )
    end

  end

end
