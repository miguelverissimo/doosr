# frozen_string_literal: true

class CreateBudgetGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :budget_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: true, foreign_key: true
      t.string :goal_type, null: false
      t.decimal :target_amount, precision: 15, scale: 2, null: false
      t.string :period, null: false, default: "monthly"
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :budget_goals, [:user_id, :goal_type, :category_id], unique: true, name: "index_budget_goals_unique_per_type_category"
  end
end
