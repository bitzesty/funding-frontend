# This encapsulates the permission to start and payments data needed to process an application started in Salesforce Experience.
class SfxPtsPayment < ApplicationRecord

    attr_accessor :validate_approved_purposes_match    
    attr_accessor :validate_agreed_costs_match
    attr_accessor :validate_cash_contributions_are_correct
    attr_accessor :validate_non_cash_contributions_are_correct

    attr_accessor :approved_purposes_match
    attr_accessor :agreed_costs_match
    attr_accessor :cash_contributions_correct
    attr_accessor :non_cash_contributions_correct

    validates :approved_purposes_match, presence: true, if: :validate_approved_purposes_match?
    validates :agreed_costs_match, presence: true, if: :validate_agreed_costs_match?
    validates :cash_contributions_correct, presence: true, if: :validate_cash_contributions_are_correct?
    validates :non_cash_contributions_correct, presence: true, if: :validate_non_cash_contributions_are_correct?

    def validate_approved_purposes_match?
      validate_approved_purposes_match == true
    end

    def validate_agreed_costs_match?
      validate_agreed_costs_match == true
    end

    def validate_cash_contributions_are_correct?
      validate_cash_contributions_are_correct == true
    end

    def validate_non_cash_contributions_are_correct?
      validate_non_cash_contributions_are_correct == true
    end

    enum application_type: {
      large_delivery: 0,
      large_development: 1,
      unknown: 2
    }

end
