# frozen_string_literal: true

# Job for checking and sending scheduled notifications
# Runs every minute via Solid Queue recurring tasks
class NotificationCheckJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "NotificationCheckJob: Checking for pending notifications..."

    result = ::PushNotifications::NotificationScheduler.call

    if result[:notified_count] > 0
      Rails.logger.info "NotificationCheckJob: Sent #{result[:notified_count]} notifications"
    end

    if result[:errors]&.any?
      Rails.logger.error "NotificationCheckJob: Errors: #{result[:errors].join(', ')}"
    end
  rescue StandardError => e
    Rails.logger.error "NotificationCheckJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
