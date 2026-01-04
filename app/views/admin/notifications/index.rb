# frozen_string_literal: true

module Views
  module Admin
    module Notifications
      class Index < ::Views::Base
        def initialize(user:, subscriptions:, logs:)
          @user = user
          @subscriptions = subscriptions
          @logs = logs
        end

        def view_template
          div(class: "container mx-auto p-6 max-w-4xl") do
            # Header
            div(class: "mb-8") do
              h1(class: "text-3xl font-bold") { "Notification Admin" }
              p(class: "text-muted-foreground mt-2") { "Manage push notifications and test delivery" }
            end

            # Permission Status
            div(id: "notification_permission_section", class: "mb-8") do
              render ::Views::Admin::NotificationPermissionStatus.new(
                user: @user,
                subscribed: @subscriptions.any?
              )
            end

            # Test Notifications Section
            div(class: "mb-8") do
              render ::Views::Admin::TestNotificationForm.new(user: @user)
            end

            # Active Subscriptions
            if @subscriptions.any?
              div(class: "mb-8") do
                h2(class: "text-xl font-semibold mb-4") { "Active Devices (#{@subscriptions.count})" }
                div(class: "space-y-2") do
                  @subscriptions.each do |subscription|
                    render ::Views::Admin::SubscriptionCard.new(subscription: subscription, user: @user)
                  end
                end
              end
            end

            # Recent Notification Logs
            div do
              h2(class: "text-xl font-semibold mb-4") { "Recent Notifications" }
              div(id: "notification_logs", class: "space-y-2") do
                if @logs.any?
                  @logs.each do |log|
                    render ::Views::Admin::Notifications::LogEntry.new(log: log)
                  end
                else
                  p(class: "text-muted-foreground") { "No notifications sent yet" }
                end
              end
            end
          end
        end
      end
    end
  end
end
