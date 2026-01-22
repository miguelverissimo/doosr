class CreateDayPaymentReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :day_payment_reminders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :payment_reminder, null: false, foreign_key: true
      t.date :reminder_date, null: false
      t.integer :days_until_cutoff, null: false

      t.timestamps
    end

    add_index :day_payment_reminders, [:user_id, :payment_reminder_id, :reminder_date], unique: true, name: "index_day_payment_reminders_unique"
    add_index :day_payment_reminders, :reminder_date
  end
end
