# frozen_string_literal: true

module Views
  module Banking
    module PaymentReminders
      class TabsContent < ::Views::Base
        def initialize(payment_reminders:)
          @payment_reminders = payment_reminders
        end

        def view_template
          div(id: "payment_reminders_content") do
            render_tabs
            render_action_buttons
          end
        end

        private

        def render_tabs
          div(data: { controller: "tabs" }) do
            div(class: "flex gap-2 mb-4") do
              render_tab_button("active", "Active", true)
              render_tab_button("upcoming", "Upcoming", false)
              render_tab_button("inactive", "Inactive", false)
            end

            render_tab_panel("active", active_reminders, true)
            render_tab_panel("upcoming", upcoming_reminders, false)
            render_tab_panel("inactive", inactive_reminders, false)
          end
        end

        def render_tab_button(id, label, active)
          button(
            type: "button",
            class: "px-4 py-2 text-sm font-medium rounded-md transition-colors #{active ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground hover:bg-accent'}",
            data: {
              action: "click->tabs#switch",
              tabs_target: "tab",
              tab_id: id
            }
          ) { label }
        end

        def render_tab_panel(id, reminders, active)
          div(
            data: { tabs_target: "panel", panel_id: id },
            class: active ? "" : "hidden"
          ) do
            if reminders.empty?
              render_empty_state(id)
            else
              div(class: "space-y-2 max-h-96 overflow-y-auto") do
                reminders.each do |reminder|
                  render ::Views::Banking::PaymentReminders::ReminderRow.new(payment_reminder: reminder)
                end
              end
            end
          end
        end

        def render_empty_state(type)
          message = case type
          when "active" then "No active payment reminders"
          when "upcoming" then "No reminders due in the next 7 days"
          when "inactive" then "No inactive reminders"
          else "No reminders"
          end

          div(class: "text-center py-8") do
            render ::Components::Icon::CreditCard.new(size: "48", class: "mx-auto text-muted-foreground mb-4")
            p(class: "text-muted-foreground") { message }
          end
        end

        def render_action_buttons
          div(class: "flex gap-2 mt-4") do
            button(
              type: "button",
              class: "flex-1 inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-dashed border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2",
              data: {
                controller: "enable-dialog",
                enable_dialog_url_value: view_context.new_banking_payment_reminder_path,
                action: "click->enable-dialog#openDialog"
              }
            ) do
              render ::Components::Icon::Add.new(size: "16", class: "mr-2")
              plain "Add Payment Reminder"
            end
          end
        end

        def active_reminders
          @payment_reminders.select(&:active?)
        end

        def upcoming_reminders
          @payment_reminders.select do |r|
            r.active? && r.cutoff_date <= Date.current + 7.days && r.cutoff_date >= Date.current
          end
        end

        def inactive_reminders
          @payment_reminders.reject(&:active?)
        end
      end
    end
  end
end
