# frozen_string_literal: true

module Admin
  class NotificationsController < ApplicationController
    before_action :authenticate_user!
    layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

    def index
      @subscriptions = current_user.push_subscriptions.order(created_at: :desc)
      @recent_logs = current_user.notification_logs.recent

      render ::Views::Admin::Notifications::Index.new(
        user: current_user,
        subscriptions: @subscriptions,
        logs: @recent_logs
      )
    end

    def send_test
      result = ::PushNotifications::Sender.new(
        user: current_user,
        title: params[:title] || "Test Notification",
        body: params[:body] || "This is a test notification from Doosr",
        data: { path: "/" },
        notification_type: :admin_test
      ).send_to_all

      respond_to do |format|
        if result[:success]
          format.turbo_stream do
            log_html = render_to_string(
              ::Views::Admin::Notifications::LogEntry.new(
                log: current_user.notification_logs.recent.first
              )
            )

            render turbo_stream: [
              turbo_stream.prepend("notification_logs", log_html),
              turbo_stream.append("body", "<script>window.toast && window.toast('Sent #{result[:sent_count]} notification(s)', { type: 'success' })</script>")
            ]
          end
        else
          format.turbo_stream do
            error_message = result[:error] || result[:errors]&.first || 'Unknown error'
            render turbo_stream: turbo_stream.append(
              "body",
              "<script>window.toast && window.toast('Failed to send notification', { type: 'error', description: '#{error_message}' })</script>"
            )
          end
        end
      end
    end

    def send_scheduled_test
      notification_time = Time.zone.parse(params[:scheduled_time])

      # Create a test item with notification_time
      item = current_user.items.create!(
        title: "Test Scheduled Notification",
        item_type: :completable,
        state: :todo,
        notification_time: notification_time
      )

      # Add to today's day
      day = current_user.days.find_by(date: Date.today) ||
            ::Days::DayOpeningService.new(user: current_user, date: Date.today).call[:day]
      day.descendant.add_active_item(item.id)
      day.descendant.save!

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            "<script>window.toast && window.toast('Test notification scheduled for #{notification_time.strftime('%H:%M')}', { type: 'success' })</script>"
          )
        end
      end
    end

    def send_to_device
      subscription = current_user.push_subscriptions.find(params[:id])

      result = ::PushNotifications::Sender.new(
        user: current_user,
        title: "Device Test",
        body: "Testing notification to specific device",
        notification_type: :admin_test
      ).send_to_subscription(subscription)

      respond_to do |format|
        if result[:success]
          format.turbo_stream do
            render turbo_stream: turbo_stream.append(
              "body",
              "<script>window.toast && window.toast('Notification sent to device', { type: 'success' })</script>"
            )
          end
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.append(
              "body",
              "<script>window.toast && window.toast('Failed to send', { type: 'error' })</script>"
            )
          end
        end
      end
    end
  end
end
