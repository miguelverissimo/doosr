# frozen_string_literal: true

module PushNotifications
  # Service for scheduling notifications for items with notification_time
  #
  # This service:
  # - Finds items with notification_time <= current time
  # - Sends notifications for those items
  # - Clears notification_time after sending
  #
  # Returns: { success: Boolean, notified_count: Integer, errors: Array }
  class NotificationScheduler
    def self.call
      new.call
    end

    def call
      pending_items = ::Item.with_pending_notifications.includes(:user)

      return { success: true, notified_count: 0 } if pending_items.empty?

      results = pending_items.map { |item| notify_item(item) }

      {
        success: true,
        notified_count: results.count { |r| r[:success] },
        errors: results.select { |r| !r[:success] }.map { |r| r[:error] }
      }
    end

    private

    def notify_item(item)
      title = "Reminder: #{item.title}"
      body = "Don't forget about this task!"
      data = {
        path: "/",
        item_id: item.id,
        tag: "item-#{item.id}"
      }

      result = ::PushNotifications::Sender.new(
        user: item.user,
        title: title,
        body: body,
        data: data,
        notification_type: :scheduled,
        item: item
      ).send_to_all

      # Clear notification_time after sending (regardless of success)
      item.update_column(:notification_time, nil)

      result
    rescue StandardError => e
      Rails.logger.error "Failed to notify item #{item.id}: #{e.message}"
      { success: false, error: e.message }
    end
  end
end
