# frozen_string_literal: true

class NotificationChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_user

    stream_from "notifications:#{current_user.id}"

    Rails.logger.debug "=== NotificationChannel subscribed for user #{current_user.id} ==="
  end

  def unsubscribed
    Rails.logger.debug "=== NotificationChannel unsubscribed for user #{current_user&.id} ==="
  end
end
