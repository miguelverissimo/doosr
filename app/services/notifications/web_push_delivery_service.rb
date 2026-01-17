# frozen_string_literal: true

module Notifications
  # Service for delivering notifications via Web Push
  #
  # This service:
  # - Builds Web Push payload with title, body, icon, and click action
  # - Sends to all user's registered push subscriptions
  # - Handles expired/invalid subscriptions by removing them
  # - Respects user push_enabled preference
  #
  # Returns: { success: Boolean, sent_count: Integer, failed_count: Integer, errors: Array }
  class WebPushDeliveryService
    attr_reader :notification

    def initialize(notification)
      @notification = notification
    end

    def deliver
      unless push_enabled?
        return { success: false, error: "Push notifications disabled for user" }
      end

      subscriptions = notification.user.push_subscriptions.active
      if subscriptions.empty?
        return { success: false, error: "No active subscriptions found" }
      end

      results = subscriptions.map { |sub| send_to_subscription(sub) }

      {
        success: results.any? { |r| r[:success] },
        sent_count: results.count { |r| r[:success] },
        failed_count: results.count { |r| !r[:success] },
        errors: results.select { |r| !r[:success] }.map { |r| r[:error] }
      }
    end

    private

    def push_enabled?
      notification.user.notification_preference(:push_enabled)
    end

    def send_to_subscription(subscription)
      payload = build_payload

      begin
        ::Webpush.payload_send(
          message: JSON.generate(payload),
          endpoint: subscription.endpoint,
          p256dh: subscription.p256dh_key,
          auth: subscription.auth_key,
          vapid: vapid_config
        )

        subscription.touch_last_used!
        { success: true, subscription: subscription }
      rescue ::Webpush::Unauthorized => e
        Rails.logger.error "Push notification unauthorized: #{e.message}"
        subscription.destroy
        { success: false, error: e.message }
      rescue ::Webpush::ExpiredSubscription => e
        Rails.logger.error "Push subscription expired: #{e.message}"
        subscription.destroy
        { success: false, error: e.message }
      rescue StandardError => e
        Rails.logger.error "Push notification failed: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        if e.message.include?("410") || e.message.include?("404") || e.message.include?("Expired")
          subscription.destroy
        end

        { success: false, error: e.message }
      end
    end

    def build_payload
      base_url = "https://#{ENV.fetch('APP_HOST', 'localhost:3000')}"
      click_path = find_item_day_path

      {
        title: notification.title || notification.item.title,
        options: {
          body: notification.body || "Reminder for your task",
          icon: "#{base_url}/web-app-manifest-192x192.png",
          badge: "#{base_url}/web-app-manifest-192x192.png",
          data: {
            path: click_path,
            notification_id: notification.id,
            item_id: notification.item_id,
            timestamp: Time.current.to_i
          },
          tag: "notification-#{notification.id}",
          requireInteraction: false
        }
      }
    end

    def find_item_day_path
      item = notification.item
      day = find_root_day(item)

      if day
        "/day?date=#{day.date.iso8601}"
      else
        "/"
      end
    end

    def find_root_day(item)
      containing_descendant = Descendant.containing_item(item.id)
      return nil unless containing_descendant

      descendable = containing_descendant.descendable

      while descendable.is_a?(Item)
        containing_descendant = Descendant.containing_item(descendable.id)
        break unless containing_descendant

        descendable = containing_descendant.descendable
      end

      descendable.is_a?(Day) ? descendable : nil
    end

    def vapid_config
      {
        subject: ENV.fetch("VAPID_SUBJECT", "mailto:admin@doosr.bfsh.app"),
        public_key: ENV.fetch("VAPID_PUBLIC_KEY"),
        private_key: ENV.fetch("VAPID_PRIVATE_KEY")
      }
    end
  end
end
