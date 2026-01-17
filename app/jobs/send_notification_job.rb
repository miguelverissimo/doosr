# frozen_string_literal: true

# Job for processing and sending due scheduled notifications
# Runs every minute via Solid Queue recurring tasks
class SendNotificationJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "SendNotificationJob: Checking for due notifications..."

    due_notifications = Notification.due.includes(:user, :item)

    return if due_notifications.empty?

    sent_count = 0
    error_count = 0

    due_notifications.find_each do |notification|
      if process_notification(notification)
        sent_count += 1
      else
        error_count += 1
      end
    end

    Rails.logger.info "SendNotificationJob: Sent #{sent_count} notifications, #{error_count} errors"
  rescue StandardError => e
    Rails.logger.error "SendNotificationJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def process_notification(notification)
    if in_quiet_hours?(notification.user)
      Rails.logger.debug "SendNotificationJob: Skipping notification #{notification.id} - user in quiet hours"
      return false
    end

    channels = notification.channels || []
    success = false

    if channels.include?("push")
      result = deliver_push(notification)
      success = result[:success] if result
    end

    if channels.include?("in_app")
      success = true
    end

    if success
      notification.mark_sent!
      Rails.logger.info "SendNotificationJob: Notification #{notification.id} sent successfully"

      broadcast_badge_update(notification.user)
    end

    success
  rescue StandardError => e
    Rails.logger.error "SendNotificationJob: Failed to process notification #{notification.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    false
  end

  def deliver_push(notification)
    ::Notifications::WebPushDeliveryService.new(notification).deliver
  end

  def in_quiet_hours?(user)
    quiet_start = user.notification_preference(:quiet_hours_start)
    quiet_end = user.notification_preference(:quiet_hours_end)

    return false if quiet_start.nil? || quiet_end.nil?

    current_time = Time.current.strftime("%H:%M")

    if quiet_start <= quiet_end
      current_time >= quiet_start && current_time < quiet_end
    else
      current_time >= quiet_start || current_time < quiet_end
    end
  end

  def broadcast_badge_update(user)
    count = user.unread_notifications_count
    html = ApplicationController.render(
      partial: "notifications/badge_update",
      locals: { count: count }
    )

    ActionCable.server.broadcast("notifications:#{user.id}", { html: html })
    Rails.logger.debug "SendNotificationJob: Broadcast badge update to notifications:#{user.id} (count: #{count})"
  rescue StandardError => e
    Rails.logger.error "SendNotificationJob: Failed to broadcast badge update: #{e.message}"
  end
end
