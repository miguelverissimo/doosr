# frozen_string_literal: true

class AddBankAccountAndTransferToBankTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :bank_transactions, :bank_account, foreign_key: true, null: true
    add_column :bank_transactions, :is_transfer, :boolean, default: false, null: false
    add_reference :bank_transactions, :linked_transfer, foreign_key: { to_table: :bank_transactions }, null: true

    # Update unique constraint for row_hash to be per-account
    remove_index :bank_transactions, [ :user_id, :row_hash ]

    # Unique per bank_account when bank_account_id is present
    add_index :bank_transactions, [ :bank_account_id, :row_hash ],
      unique: true,
      where: "bank_account_id IS NOT NULL",
      name: "idx_bank_transactions_on_account_row_hash"

    # Unique per user when bank_account_id is NULL (legacy transactions)
    add_index :bank_transactions, [ :user_id, :row_hash ],
      unique: true,
      where: "bank_account_id IS NULL",
      name: "idx_bank_transactions_on_user_row_hash_legacy"
  end
end
