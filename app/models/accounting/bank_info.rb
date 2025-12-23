module Accounting
  class BankInfo < ApplicationRecord
    belongs_to :user

    enum :kind, {
      user: :user,
      customer: :customer,
      supplier: :supplier
    }, default: :user, validate: true

    validates :name, presence: true
    validate :validate_bank_details

    def is_eu?
      iban.present? && swift_bic.present?
    end

    def is_non_eu?
      routing_number.present? && account_number.present?
    end

    private

    # Ensure we have EITHER:
    # - iban + swift_bic
    # OR
    # - routing_number + account_number
    def validate_bank_details
      has_iban_combo = iban.present? && swift_bic.present?
      has_routing_combo = routing_number.present? && account_number.present?

      # If neither full combo is present, add a base error
      unless has_iban_combo || has_routing_combo
        errors.add(
          :base,
          "must have either IBAN and SWIFT/BIC or routing number and account number"
        )
      end

      # If one of the fields in a pair is present, require the other
      if iban.present? ^ swift_bic.present?
        errors.add(:iban, "and SWIFT/BIC must both be present when using IBAN details")
        errors.add(:swift_bic, "and IBAN must both be present when using IBAN details")
      end

      if routing_number.present? ^ account_number.present?
        errors.add(:routing_number, "and account number must both be present when using routing details")
        errors.add(:account_number, "and routing number must both be present when using routing details")
      end
    end
  end
end
