# frozen_string_literal: true

class ::Components::NotificationsDropdown < ::Components::Base
  def initialize(notifications:, **attrs)
    @notifications = notifications
    super(**attrs)
  end

  def view_template
    div(
      id: "notifications_dropdown",
      class: "absolute right-0 top-full mt-2 w-80 bg-background border rounded-lg shadow-lg z-50"
    ) do
      render_header
      render_notifications_list
    end
  end

  private

  attr_reader :notifications

  def render_header
    div(class: "flex items-center justify-between px-4 py-3 border-b") do
      span(class: "font-semibold text-sm") { "Notifications" }
      render_mark_all_read_button if notifications.any?
    end
  end

  def render_mark_all_read_button
    render RubyUI::Form.new(
      action: view_context.mark_all_read_notifications_path,
      method: :post,
      data: { turbo_stream: true }
    ) do
      render RubyUI::Input.new(
        type: :hidden,
        name: "authenticity_token",
        value: view_context.form_authenticity_token
      )
      Button(
        type: :submit,
        variant: :ghost,
        size: :sm,
        class: "text-xs h-auto py-1"
      ) { "Mark all read" }
    end
  end

  def render_notifications_list
    div(id: "notifications_list", class: "max-h-80 overflow-y-auto") do
      if notifications.empty?
        render_empty_state
      else
        notifications.each do |notification|
          render ::Components::NotificationItem.new(notification: notification)
        end
      end
    end
  end

  def render_empty_state
    div(class: "px-4 py-8 text-center text-muted-foreground text-sm") do
      "No notifications"
    end
  end
end
