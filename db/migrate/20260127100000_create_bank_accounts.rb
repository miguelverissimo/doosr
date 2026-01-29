# frozen_string_literal: true

class CreateBankAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :bank_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :account_type, default: "checking"
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :bank_accounts, [ :user_id, :name ], unique: true
  end
end
