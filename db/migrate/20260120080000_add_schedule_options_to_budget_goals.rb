# frozen_string_literal: true

class AddScheduleOptionsToBudgetGoals < ActiveRecord::Migration[8.1]
  def change
    add_column :budget_goals, :start_date, :date
    add_column :budget_goals, :payment_months, :integer, array: true, default: []
    add_column :budget_goals, :name, :string

    add_index :budget_goals, :start_date
  end
end
