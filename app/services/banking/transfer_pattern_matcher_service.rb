# frozen_string_literal: true

module Banking
  class TransferPatternMatcherService
    def initialize(user)
      @user = user
    end

    # Apply pattern to existing non-transfer transactions that match
    def apply_to_existing(pattern)
      transaction_ids = matching_non_transfers(pattern).pluck(:id)
      return 0 if transaction_ids.empty?

      count = @user.bank_transactions.where(id: transaction_ids).update_all(is_transfer: true)
      add_transfers_category(transaction_ids)
      count
    end

    # Rematch: mark all matching non-transfer transactions as transfers
    def rematch(pattern)
      transaction_ids = matching_non_transfers(pattern).pluck(:id)
      return 0 if transaction_ids.empty?

      count = @user.bank_transactions.where(id: transaction_ids).update_all(is_transfer: true)
      add_transfers_category(transaction_ids)
      count
    end

    # Before destroy: unmark transactions that matched this pattern
    def unmark_matching(pattern)
      transaction_ids = @user.bank_transactions
        .where(is_transfer: true)
        .where("LOWER(description) LIKE ?", "%#{pattern.pattern.downcase}%")
        .pluck(:id)

      return if transaction_ids.empty?

      @user.bank_transactions.where(id: transaction_ids).update_all(is_transfer: false)
      remove_transfers_category(transaction_ids)
    end

    private

    def matching_non_transfers(pattern)
      @user.bank_transactions
        .where(is_transfer: false)
        .where("LOWER(description) LIKE ?", "%#{pattern.pattern.downcase}%")
    end

    def transfers_category
      @transfers_category ||= @user.categories.find_or_create_by!(name: "Transfers") do |category|
        category.color = "#109648"
      end
    end

    def add_transfers_category(transaction_ids)
      return if transaction_ids.empty?

      existing_categorizations = TransactionCategorization
        .where(bank_transaction_id: transaction_ids, category_id: transfers_category.id)
        .pluck(:bank_transaction_id)

      new_categorizations = (transaction_ids - existing_categorizations).map do |transaction_id|
        { bank_transaction_id: transaction_id, category_id: transfers_category.id, user_id: @user.id }
      end

      TransactionCategorization.insert_all(new_categorizations) if new_categorizations.any?
    end

    def remove_transfers_category(transaction_ids)
      return if transaction_ids.empty?

      TransactionCategorization
        .where(bank_transaction_id: transaction_ids, category_id: transfers_category.id)
        .delete_all
    end
  end
end
