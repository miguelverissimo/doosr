class AddNotificationTimeToPaymentReminders < ActiveRecord::Migration[8.1]
  def change
    add_column :payment_reminders, :notification_time, :datetime
  end
end
