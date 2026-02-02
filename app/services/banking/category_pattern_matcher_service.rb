# frozen_string_literal: true

module Banking
  class CategoryPatternMatcherService
    def initialize(user)
      @user = user
    end

    # Apply pattern to existing uncategorized transactions that match
    def apply_to_existing(pattern)
      matching_transactions = @user.bank_transactions
        .without_categorizations
        .where("LOWER(description) LIKE ?", "%#{pattern.pattern.downcase}%")

      count = 0
      matching_transactions.find_each do |transaction|
        transaction.update!(category_pattern_id: pattern.id)
        transaction.set_categories([ pattern.category_id ])
        count += 1
      end
      count
    end

    # Rematch: clear non-matching, update still-matching, apply to new matches
    def rematch(pattern)
      unmatched_count = 0
      updated_count = 0
      new_count = 0

      # 1. Check transactions that had this pattern
      pattern.bank_transactions.find_each do |transaction|
        if pattern.matches?(transaction.description)
          # Still matches - update category in case it changed
          transaction.set_categories([ pattern.category_id ])
          updated_count += 1
        else
          # No longer matches - clear the association
          transaction.transaction_categorizations.destroy_all
          transaction.update_columns(category_pattern_id: nil)
          unmatched_count += 1
        end
      end

      # 2. Apply to uncategorized transactions that now match
      @user.bank_transactions
        .without_categorizations
        .where("LOWER(description) LIKE ?", "%#{pattern.pattern.downcase}%")
        .find_each do |transaction|
          transaction.update!(category_pattern_id: pattern.id)
          transaction.set_categories([ pattern.category_id ])
          new_count += 1
        end

      { unmatched: unmatched_count, updated: updated_count, new_matches: new_count }
    end
  end
end
