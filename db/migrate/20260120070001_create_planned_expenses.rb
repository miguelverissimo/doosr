# frozen_string_literal: true

class CreatePlannedExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :planned_expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: true, foreign_key: true
      t.references :recurring_group, null: true, foreign_key: true
      t.references :matched_transaction, null: true, foreign_key: { to_table: :bank_transactions }
      t.string :description, null: false
      t.decimal :expected_amount, precision: 15, scale: 2, null: false
      t.date :due_date, null: false
      t.string :expense_type, null: false, default: "one_time"
      t.boolean :completed, null: false, default: false

      t.timestamps
    end

    add_index :planned_expenses, [ :user_id, :due_date ]
    add_index :planned_expenses, [ :user_id, :completed ]
    add_index :planned_expenses, [ :recurring_group_id, :due_date ], name: "index_planned_expenses_on_recurring_group_and_date"
  end
end
