# frozen_string_literal: true

class PaymentReminderNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id:, payment_reminder_id:, day_payment_reminder_id:, title:, body:)
    user = User.find_by(id: user_id)
    return unless user

    payment_reminder = PaymentReminder.find_by(id: payment_reminder_id)
    return unless payment_reminder&.active?

    day_payment_reminder = DayPaymentReminder.find_by(id: day_payment_reminder_id)
    return unless day_payment_reminder
    return if day_payment_reminder.paid?
    return if day_payment_reminder.notified_at.present?

    result = ::PushNotifications::Sender.new(
      user: user,
      title: title,
      body: body,
      data: {
        path: "/banking/forecasts",
        payment_reminder_id: payment_reminder_id,
        day_payment_reminder_id: day_payment_reminder_id,
        tag: "payment-reminder-#{payment_reminder_id}"
      },
      notification_type: :payment_reminder
    ).send_to_all

    # Mark as notified if at least one notification was sent successfully
    if result[:success] && result[:sent_count].to_i > 0
      day_payment_reminder.update!(notified_at: Time.current)
    end
  end
end
