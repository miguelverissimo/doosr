# frozen_string_literal: true

class ::Components::NotificationItem < ::Components::Base
  def initialize(notification:, **attrs)
    @notification = notification
    super(**attrs)
  end

  def view_template
    a(
      id: dom_id(notification),
      href: view_context.notification_path(notification),
      class: [
        "block px-4 py-3 hover:bg-muted/50 cursor-pointer border-b last:border-b-0 transition-colors",
        unread? ? "bg-muted/30" : "opacity-60"
      ],
      data: { turbo_frame: "_top" }
    ) do
      render_title
      render_reminder_time
      render_relative_time
    end
  end

  private

  attr_reader :notification

  def unread?
    notification.read_at.nil?
  end

  def render_title
    div(class: [
      "text-sm",
      unread? ? "font-semibold" : "font-normal"
    ]) do
      plain notification.item&.title || "Reminder"
    end
  end

  def render_reminder_time
    return unless notification.remind_at

    div(class: "text-xs text-muted-foreground mt-0.5") do
      plain format_reminder_time(notification.remind_at)
    end
  end

  def render_relative_time
    return unless notification.sent_at

    div(class: "text-xs text-muted-foreground/70 mt-0.5") do
      plain time_ago_in_words(notification.sent_at)
    end
  end

  def format_reminder_time(time)
    time.strftime("%b %-d, %-I:%M %p")
  end

  def time_ago_in_words(time)
    diff = Time.current - time
    if diff < 60
      "Just now"
    elsif diff < 3600
      "#{(diff / 60).to_i} minutes ago"
    elsif diff < 86400
      "#{(diff / 3600).to_i} hours ago"
    else
      "#{(diff / 86400).to_i} days ago"
    end
  end

  def dom_id(notification)
    "notification_#{notification.id}"
  end
end
