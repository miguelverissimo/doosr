# frozen_string_literal: true

class ::Components::NotificationBell < ::Components::Base
  def initialize(user:, **attrs)
    @user = user
    super(**attrs)
  end

  def view_template
    div(
      id: "notification_bell",
      class: "relative",
      data: { controller: "notification-bell" }
    ) do
      Button(
        variant: :ghost,
        icon: true,
        size: :sm,
        title: "Notifications",
        data: { action: "click->notification-bell#toggle" }
      ) do
        render ::Components::Icon::Bell.new(size: "20")
      end
      render_badge
    end
  end

  private

  attr_reader :user

  def render_badge
    turbo_frame_tag("notification_badge") do
      render ::Components::NotificationBadge.new(count: user.unread_notifications_count)
    end
  end
end
