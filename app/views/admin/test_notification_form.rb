# frozen_string_literal: true

module Views
  module Admin
    class TestNotificationForm < ::Views::Base
      def initialize(user:)
        @user = user
      end

      def view_template
        div(class: "p-6 border rounded-lg bg-card") do
          h3(class: "text-lg font-semibold mb-4") { "Send Test Notification" }

          # Immediate test
          form(
            action: view_context.send_test_admin_notifications_path,
            method: "post",
            data: { turbo_stream: true },
            class: "space-y-4 mb-6"
          ) do
            view_context.hidden_field_tag :authenticity_token, view_context.form_authenticity_token

            div do
              label(class: "text-sm font-medium mb-2 block") { "Title" }
              input(
                type: "text",
                name: "title",
                value: "Test Notification",
                class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
              )
            end

            div do
              label(class: "text-sm font-medium mb-2 block") { "Message" }
              textarea(
                name: "body",
                rows: "3",
                class: "flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
              ) { "This is a test notification from Doosr" }
            end

            button(
              type: "submit",
              class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2"
            ) { "Send Now" }
          end

          # Scheduled test
          div(class: "pt-6 border-t") do
            h4(class: "text-md font-semibold mb-4") { "Schedule Test Notification" }

            form(
              action: view_context.send_scheduled_test_admin_notifications_path,
              method: "post",
              data: { turbo_stream: true },
              class: "space-y-4"
            ) do
              view_context.hidden_field_tag :authenticity_token, view_context.form_authenticity_token

              div do
                label(class: "text-sm font-medium mb-2 block") { "Scheduled Time" }
                input(
                  type: "datetime-local",
                  name: "scheduled_time",
                  value: (Time.current + 5.minutes).strftime("%Y-%m-%dT%H:%M"),
                  class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background",
                  placeholder: "DD/MM/YYYY HH:MM"
                )
                p(class: "text-xs text-muted-foreground mt-1") { "Format adapts to your browser locale" }
              end

              button(
                type: "submit",
                class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2"
              ) { "Schedule Test" }
            end
          end
        end
      end
    end
  end
end
