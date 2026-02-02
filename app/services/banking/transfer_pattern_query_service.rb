# frozen_string_literal: true

module Banking
  class TransferPatternQueryService
    def initialize(user)
      @user = user
    end

    def call
      patterns = @user.transfer_patterns.by_length_desc

      patterns.map do |pattern|
        count = @user.bank_transactions
          .where(is_transfer: true)
          .where("LOWER(description) LIKE ?", "%#{pattern.pattern.downcase}%")
          .count
        pattern.define_singleton_method(:matched_transactions_count) { count }
        pattern
      end
    end
  end
end
