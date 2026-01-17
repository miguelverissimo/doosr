# frozen_string_literal: true

module Components
  module Settings
    class NotificationPreferencesTab < ::Components::Base
      DIALOG_ID = "notification_preferences_tab"

      def initialize(user:)
        @user = user
      end

      def view_template
        form(
          id: DIALOG_ID,
          action: view_context.update_notification_preferences_settings_path,
          method: "post",
          class: "space-y-6",
          data: {
            turbo_stream: true
          }
        ) do
          render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
          render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch")

          render_description
          render_toggles_section
          render_quiet_hours_section
          render_save_button
        end
      end

      private

      def render_description
        p(class: "text-sm text-muted-foreground") do
          plain "Configure how and when you receive notifications."
        end
      end

      def render_toggles_section
        div(class: "space-y-3") do
          render_toggle_field(
            name: "push_enabled",
            label: "Push notifications",
            description: "Receive notifications on your devices even when the app is closed.",
            checked: @user.notification_preference("push_enabled")
          )

          render_toggle_field(
            name: "in_app_enabled",
            label: "In-app notifications",
            description: "Show notifications in the app's notification bell.",
            checked: @user.notification_preference("in_app_enabled")
          )
        end
      end

      def render_quiet_hours_section
        div(class: "border rounded-lg p-4 bg-muted/50") do
          h4(class: "text-sm font-semibold mb-1") { "Quiet Hours" }
          p(class: "text-sm text-muted-foreground mb-4") do
            plain "During quiet hours, notifications will be held until quiet hours end."
          end

          div(class: "flex items-center gap-4") do
            render RubyUI::FormField.new(class: "flex-1") do
              render RubyUI::FormFieldLabel.new { "Start time" }
              render RubyUI::Input.new(
                type: :time,
                name: "notification_preferences[quiet_hours_start]",
                value: @user.notification_preference("quiet_hours_start"),
                class: "date-input-icon-light-dark"
              )
            end

            render RubyUI::FormField.new(class: "flex-1") do
              render RubyUI::FormFieldLabel.new { "End time" }
              render RubyUI::Input.new(
                type: :time,
                name: "notification_preferences[quiet_hours_end]",
                value: @user.notification_preference("quiet_hours_end"),
                class: "date-input-icon-light-dark"
              )
            end
          end
        end
      end

      def render_save_button
        div(class: "pt-4 flex justify-end") do
          render RubyUI::Button.new(type: "submit", variant: :primary) { "Save Settings" }
        end
      end

      def render_toggle_field(name:, label:, description:, checked:)
        div(class: "flex items-start justify-between space-x-4 rounded-lg border p-4") do
          div(class: "flex-1") do
            label(class: "text-sm font-medium leading-none block mb-1", for: "notification_preferences_#{name}") { label }
            p(class: "text-sm text-muted-foreground") { description }
          end

          label(class: "relative inline-flex items-center cursor-pointer") do
            render RubyUI::Input.new(type: :hidden, name: "notification_preferences[#{name}]", value: "false")

            input(
              type: "checkbox",
              name: "notification_preferences[#{name}]",
              value: "true",
              id: "notification_preferences_#{name}",
              class: "sr-only peer",
              checked: checked
            )

            div(
              class: [
                "w-11 h-6 bg-input rounded-full peer",
                "peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-ring peer-focus:ring-offset-2",
                "peer-checked:after:translate-x-full",
                "after:content-[''] after:absolute after:top-0.5 after:left-[2px]",
                "after:bg-background after:rounded-full after:h-5 after:w-5",
                "after:transition-all peer-checked:bg-primary"
              ]
            )
          end
        end
      end
    end
  end
end
