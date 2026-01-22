# frozen_string_literal: true

class CreatePaymentReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_reminders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.date :cutoff_date, null: false
      t.string :payment_url
      t.jsonb :reminder_days_before, null: false, default: [7, 3, 1]
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :payment_reminders, [:user_id, :active]
    add_index :payment_reminders, [:user_id, :cutoff_date]
  end
end
