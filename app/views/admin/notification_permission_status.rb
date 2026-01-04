# frozen_string_literal: true

module Views
  module Admin
    class NotificationPermissionStatus < ::Views::Base
      def initialize(user:, subscribed:)
        @user = user
        @subscribed = subscribed
      end

      def view_template
        div(
          class: "p-6 border rounded-lg bg-card",
          data: {
            controller: "notification-permission",
            notification_permission_vapid_public_key_value: ENV.fetch("VAPID_PUBLIC_KEY"),
            notification_permission_subscribe_url_value: view_context.push_subscriptions_path,
            notification_permission_unsubscribe_url_value: view_context.push_subscriptions_path
          }
        ) do
          div(class: "flex items-center justify-between") do
            div do
              h3(class: "text-lg font-semibold") { "Push Notifications" }
              p(
                data: { notification_permission_target: "status" },
                class: "text-sm text-muted-foreground mt-1"
              ) { "Checking status..." }
            end

            div(class: "flex gap-2") do
              # Subscribe button
              button(
                type: "button",
                class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2 hidden",
                data: {
                  notification_permission_target: "subscribeButton",
                  action: "click->notification-permission#requestPermission"
                }
              ) { "Enable Notifications" }

              # Unsubscribe button
              button(
                type: "button",
                class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2 #{@subscribed ? '' : 'hidden'}",
                data: {
                  notification_permission_target: "unsubscribeButton",
                  action: "click->notification-permission#unsubscribe"
                }
              ) { "Disable Notifications" }
            end
          end
        end
      end
    end
  end
end
