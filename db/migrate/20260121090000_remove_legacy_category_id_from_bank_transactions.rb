# frozen_string_literal: true

# IMPORTANT: Only run this migration AFTER validating that:
# 1. All transactions are properly categorized via transaction_categorizations
# 2. Category filtering and category breakdown work correctly
# 3. Budget goals and forecasts calculate correctly from transaction_categorizations
#
# To run manually after validation:
#   bin/rails db:migrate:up VERSION=20260121090000
#
# To verify before running:
#   BankTransaction.where.not(category_id: nil)
#     .where.missing(:transaction_categorizations).count
#   # Should return 0

class RemoveLegacyCategoryIdFromBankTransactions < ActiveRecord::Migration[8.1]
  def up
    # Safety check: ensure all categorized transactions have been migrated
    orphan_count = execute(<<~SQL).first["count"]
      SELECT COUNT(*) as count
      FROM bank_transactions bt
      WHERE bt.category_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM transaction_categorizations tc
          WHERE tc.bank_transaction_id = bt.id
        )
    SQL

    if orphan_count > 0
      raise "Cannot remove category_id: #{orphan_count} transactions have category_id but no transaction_categorizations record. Run data migration first."
    end

    remove_foreign_key :bank_transactions, :categories
    remove_index :bank_transactions, :category_id
    remove_column :bank_transactions, :category_id
  end

  def down
    add_column :bank_transactions, :category_id, :bigint
    add_index :bank_transactions, :category_id
    add_foreign_key :bank_transactions, :categories

    # Restore category_id from transaction_categorizations (first one for each transaction)
    execute <<~SQL
      UPDATE bank_transactions bt
      SET category_id = tc.category_id
      FROM (
        SELECT DISTINCT ON (bank_transaction_id) bank_transaction_id, category_id
        FROM transaction_categorizations
        ORDER BY bank_transaction_id, created_at ASC
      ) tc
      WHERE bt.id = tc.bank_transaction_id
    SQL
  end
end
