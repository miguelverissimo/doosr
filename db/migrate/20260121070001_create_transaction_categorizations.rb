# frozen_string_literal: true

class CreateTransactionCategorizations < ActiveRecord::Migration[8.1]
  def change
    create_table :transaction_categorizations do |t|
      t.references :bank_transaction, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: true

      t.timestamps
    end

    add_index :transaction_categorizations, [:bank_transaction_id, :category_id],
              unique: true,
              name: "index_transaction_categorizations_unique"
  end
end
