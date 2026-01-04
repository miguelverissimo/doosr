# frozen_string_literal: true

module Views
  module Admin
    class NotificationPermissionStatus < ::Views::Base
      def initialize(user:, subscribed:)
        @user = user
        @subscribed = subscribed
      end

      def view_template
        vapid_key = ENV.fetch("VAPID_PUBLIC_KEY", "")
        vapid_configured = vapid_key.present?

        div(
          class: "p-6 border rounded-lg bg-card",
          data: {
            controller: "notification-permission",
            notification_permission_vapid_public_key_value: vapid_key,
            notification_permission_subscribe_url_value: view_context.push_subscriptions_path,
            notification_permission_unsubscribe_url_value: view_context.push_subscriptions_path
          }
        ) do
          # Warning banner if VAPID keys not configured
          unless vapid_configured
            div(class: "mb-4 p-4 border border-destructive/50 bg-destructive/10 rounded-lg") do
              div(class: "flex items-start gap-3") do
                div(class: "text-destructive mt-0.5") do
                  # Warning icon (SVG)
                  svg(
                    xmlns: "http://www.w3.org/2000/svg",
                    width: "20",
                    height: "20",
                    viewBox: "0 0 24 24",
                    fill: "none",
                    stroke: "currentColor",
                    stroke_width: "2",
                    stroke_linecap: "round",
                    stroke_linejoin: "round"
                  ) do
                    path(d: "m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z")
                    line(x1: "12", x2: "12", y1: "9", y2: "13")
                    line(x1: "12", x2: "12.01", y1: "17", y2: "17")
                  end
                end
                div do
                  p(class: "font-semibold text-sm text-destructive") { "Push notifications not configured" }
                  p(class: "text-sm text-muted-foreground mt-1") do
                    plain "VAPID keys are missing. Generate keys locally with "
                    code(class: "bg-muted px-1.5 py-0.5 rounded text-xs") { "bin/rails notifications:generate_vapid_keys" }
                    plain " and add them to Coolify environment variables."
                  end
                end
              end
            end
          end

          div(class: "flex items-center justify-between") do
            div do
              h3(class: "text-lg font-semibold") { "Push Notifications" }
              p(
                data: { notification_permission_target: "status" },
                class: "text-sm text-muted-foreground mt-1"
              ) { vapid_configured ? "Checking status..." : "Server configuration required" }
            end

            div(class: "flex gap-2") do
              # Subscribe button
              button(
                type: "button",
                class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 #{vapid_configured ? 'bg-primary text-primary-foreground hover:bg-primary/90' : 'bg-muted text-muted-foreground cursor-not-allowed'} h-10 px-4 py-2 hidden",
                disabled: !vapid_configured,
                data: {
                  notification_permission_target: "subscribeButton",
                  action: vapid_configured ? "click->notification-permission#requestPermission" : ""
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
