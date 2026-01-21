# frozen_string_literal: true

class MigrateExistingCategorizations < ActiveRecord::Migration[8.1]
  def up
    # Migrate existing category_id values to transaction_categorizations table
    execute <<~SQL
      INSERT INTO transaction_categorizations (bank_transaction_id, category_id, user_id, amount, created_at, updated_at)
      SELECT id, category_id, user_id, NULL, NOW(), NOW()
      FROM bank_transactions
      WHERE category_id IS NOT NULL
    SQL
  end

  def down
    # Restore category_id values from transaction_categorizations
    # Only restore if there's a single categorization per transaction
    execute <<~SQL
      UPDATE bank_transactions bt
      SET category_id = tc.category_id
      FROM (
        SELECT bank_transaction_id, category_id
        FROM transaction_categorizations
        WHERE bank_transaction_id IN (
          SELECT bank_transaction_id
          FROM transaction_categorizations
          GROUP BY bank_transaction_id
          HAVING COUNT(*) = 1
        )
      ) tc
      WHERE bt.id = tc.bank_transaction_id
    SQL

    # Delete all transaction_categorizations
    execute "DELETE FROM transaction_categorizations"
  end
end
