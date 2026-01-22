# frozen_string_literal: true

module Views
  module Banking
    module PaymentReminders
      class ReminderRow < ::Views::Base
        def initialize(payment_reminder:)
          @payment_reminder = payment_reminder
        end

        def view_template
          div(
            id: "payment_reminder_#{@payment_reminder.id}",
            class: "flex items-center justify-between p-3 rounded-lg border bg-card #{row_classes}"
          ) do
            render_reminder_info
            render_actions
          end
        end

        private

        def row_classes
          if !@payment_reminder.active?
            "opacity-60"
          elsif @payment_reminder.overdue?
            "border-red-300 bg-red-50 dark:border-red-800 dark:bg-red-950"
          elsif @payment_reminder.due_today?
            "border-amber-300 bg-amber-50 dark:border-amber-800 dark:bg-amber-950"
          else
            ""
          end
        end

        def render_reminder_info
          div(class: "flex items-center gap-3") do
            render_icon
            div do
              div(class: "flex items-center gap-2") do
                span(class: "font-medium #{@payment_reminder.active? ? '' : 'text-muted-foreground'}") do
                  plain @payment_reminder.title
                end
                render_status_badge
              end
              div(class: "flex items-center gap-2 text-sm text-muted-foreground") do
                render_due_date
                span { "" }
                render_reminder_schedule
              end
            end
          end
        end

        def render_icon
          if @payment_reminder.overdue?
            render ::Components::Icon::CreditCard.new(size: "16", class: "text-red-500")
          elsif @payment_reminder.due_today?
            render ::Components::Icon::CreditCard.new(size: "16", class: "text-amber-500")
          else
            render ::Components::Icon::CreditCard.new(size: "16", class: "text-muted-foreground")
          end
        end

        def render_status_badge
          return unless !@payment_reminder.active?

          span(class: "text-xs px-2 py-0.5 rounded-full bg-muted text-muted-foreground") { "Inactive" }
        end

        def render_due_date
          if @payment_reminder.overdue?
            span(class: "text-red-500 font-medium") do
              plain "Overdue: #{format_date(@payment_reminder.cutoff_date)}"
            end
          elsif @payment_reminder.due_today?
            span(class: "text-amber-600 dark:text-amber-400 font-medium") do
              plain "Due today"
            end
          else
            span { "Due: #{format_date(@payment_reminder.cutoff_date)}" }
          end
        end

        def render_reminder_schedule
          days = @payment_reminder.reminder_days_before.sort.reverse
          formatted = days.map { |d| format_reminder_day(d) }.join(", ")
          span(class: "text-xs") { "Reminders: #{formatted}" }
        end

        def format_reminder_day(days)
          case days
          when 30 then "1mo"
          when 21 then "3w"
          when 14 then "2w"
          when 7 then "1w"
          when 0 then "due"
          else "#{days}d"
          end
        end

        def render_actions
          div(class: "flex items-center gap-1") do
            render_payment_link if @payment_reminder.payment_url.present?
            render_clone_button
            render_edit_button
            render_delete_button
          end
        end

        def render_payment_link
          a(
            href: @payment_reminder.payment_url,
            target: "_blank",
            rel: "noopener noreferrer",
            class: "p-2 rounded-md hover:bg-accent text-blue-500",
            title: "Open payment page"
          ) do
            render ::Components::Icon::ExternalLink.new(size: "16")
          end
        end

        def render_clone_button
          button(
            type: "button",
            class: "p-2 rounded-md hover:bg-accent",
            title: "Clone reminder",
            data: {
              controller: "enable-dialog",
              enable_dialog_url_value: view_context.clone_banking_payment_reminder_path(@payment_reminder),
              enable_dialog_loading_message_value: "Loading...",
              action: "click->enable-dialog#openDialog"
            }
          ) do
            render ::Components::Icon::Copy.new(size: "16")
          end
        end

        def render_edit_button
          button(
            type: "button",
            class: "p-2 rounded-md hover:bg-accent",
            data: {
              controller: "enable-dialog",
              enable_dialog_url_value: view_context.edit_banking_payment_reminder_path(@payment_reminder),
              action: "click->enable-dialog#openDialog"
            }
          ) do
            render ::Components::Icon::Edit.new(size: "16")
          end
        end

        def render_delete_button
          button(
            type: "button",
            class: "p-2 rounded-md hover:bg-destructive/10 text-destructive",
            data: {
              controller: "delete-confirm",
              delete_confirm_url_value: view_context.banking_payment_reminder_path(@payment_reminder),
              delete_confirm_message_value: "Are you sure you want to delete this payment reminder?",
              action: "click->delete-confirm#confirm"
            }
          ) do
            render ::Components::Icon::Trash.new(size: "16")
          end
        end

        def format_date(date)
          if date.year == Date.current.year
            date.strftime("%b %d")
          else
            date.strftime("%b %d, %Y")
          end
        end
      end
    end
  end
end
