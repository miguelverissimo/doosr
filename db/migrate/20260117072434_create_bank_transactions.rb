class CreateBankTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :category_id, null: true
      t.date :date, null: false
      t.string :description, null: false
      t.decimal :value, precision: 12, scale: 2, null: false
      t.string :row_hash, null: false

      t.timestamps
    end

    add_index :bank_transactions, :date
    add_index :bank_transactions, :category_id
    add_index :bank_transactions, [ :user_id, :row_hash ], unique: true
  end
end
