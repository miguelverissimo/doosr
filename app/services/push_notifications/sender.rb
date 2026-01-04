# frozen_string_literal: true

module PushNotifications
  # Service for sending push notifications
  #
  # This service:
  # - Sends notifications to one or all user subscriptions
  # - Handles VAPID authentication
  # - Creates notification logs
  # - Removes stale/failed subscriptions
  #
  # Returns: { success: Boolean, sent_count: Integer, failed_count: Integer, errors: Array }
  class Sender
    attr_reader :user, :title, :body, :data, :notification_type, :item

    def initialize(user:, title:, body:, data: {}, notification_type: :test, item: nil)
      @user = user
      @title = title
      @body = body
      @data = data
      @notification_type = notification_type
      @item = item
    end

    def send_to_all
      subscriptions = user.push_subscriptions.active
      return { success: false, error: "No active subscriptions found" } if subscriptions.empty?

      results = subscriptions.map { |sub| send_to_subscription(sub) }

      {
        success: true,
        sent_count: results.count { |r| r[:success] },
        failed_count: results.count { |r| !r[:success] },
        errors: results.select { |r| !r[:success] }.map { |r| r[:error] }
      }
    end

    def send_to_subscription(subscription)
      payload = build_payload
      log = create_notification_log(subscription)

      begin
        # Use the webpush gem's high-level API
        response = ::Webpush.payload_send(
          message: JSON.generate(payload),
          endpoint: subscription.endpoint,
          p256dh: subscription.p256dh_key,
          auth: subscription.auth_key,
          vapid: vapid_config
        )

        subscription.touch_last_used!
        log.update!(status: :sent, sent_at: Time.current)
        { success: true, subscription: subscription }
      rescue ::Webpush::Unauthorized => e
        Rails.logger.error "Push notification unauthorized: #{e.message}"
        log.update!(status: :failed, error_message: e.message)
        subscription.destroy
        { success: false, error: e.message }
      rescue ::Webpush::ExpiredSubscription => e
        Rails.logger.error "Push subscription expired: #{e.message}"
        log.update!(status: :failed, error_message: e.message)
        subscription.destroy
        { success: false, error: e.message }
      rescue StandardError => e
        Rails.logger.error "Push notification failed: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        log.update!(status: :failed, error_message: e.message)

        # Remove subscription on certain errors
        if e.message.include?("410") || e.message.include?("404") || e.message.include?("Expired")
          subscription.destroy
        end

        { success: false, error: e.message }
      end
    end

    private

    def build_payload
      base_url = "https://#{ENV.fetch('APP_HOST', 'localhost:3000')}"

      {
        title: title,
        options: {
          body: body,
          icon: "#{base_url}/web-app-manifest-192x192.png",
          badge: "#{base_url}/web-app-manifest-192x192.png",
          data: data.merge(
            path: data[:path] || "/",
            timestamp: Time.current.to_i
          ),
          tag: data[:tag] || "notification-#{SecureRandom.hex(8)}",
          requireInteraction: false
        }
      }
    end

    def create_notification_log(subscription)
      user.notification_logs.create!(
        push_subscription: subscription,
        item: item,
        notification_type: notification_type,
        status: :pending,
        payload: build_payload
      )
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
