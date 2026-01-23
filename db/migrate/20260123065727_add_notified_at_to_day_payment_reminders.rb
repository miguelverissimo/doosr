class AddNotifiedAtToDayPaymentReminders < ActiveRecord::Migration[8.1]
  def change
    add_column :day_payment_reminders, :notified_at, :datetime
  end
end
