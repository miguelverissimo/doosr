# frozen_string_literal: true

module Banking
  class TransferPatternMatcherService
    def initialize(user)
      @user = user
    end

    # Apply pattern to existing non-transfer transactions that match
    def apply_to_existing(pattern)
      @user.bank_transactions
        .where(is_transfer: false)
        .where("LOWER(description) LIKE ?", "%#{pattern.pattern.downcase}%")
        .update_all(is_transfer: true)
    end

    # Rematch: mark all matching non-transfer transactions as transfers
    def rematch(pattern)
      @user.bank_transactions
        .where(is_transfer: false)
        .where("LOWER(description) LIKE ?", "%#{pattern.pattern.downcase}%")
        .update_all(is_transfer: true)
    end

    # Before destroy: unmark transactions that matched this pattern
    def unmark_matching(pattern)
      @user.bank_transactions
        .where(is_transfer: true)
        .where("LOWER(description) LIKE ?", "%#{pattern.pattern.downcase}%")
        .update_all(is_transfer: false)
    end
  end
end
