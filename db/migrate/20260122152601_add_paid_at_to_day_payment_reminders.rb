class AddPaidAtToDayPaymentReminders < ActiveRecord::Migration[8.1]
  def change
    add_column :day_payment_reminders, :paid_at, :datetime
  end
end
