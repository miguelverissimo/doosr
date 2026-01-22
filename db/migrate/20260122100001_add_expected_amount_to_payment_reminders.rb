# frozen_string_literal: true

class AddExpectedAmountToPaymentReminders < ActiveRecord::Migration[8.1]
  def change
    add_column :payment_reminders, :expected_amount, :decimal, precision: 10, scale: 2
  end
end
