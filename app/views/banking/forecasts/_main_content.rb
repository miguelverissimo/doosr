# frozen_string_literal: true

module Views
  module Banking
    module Forecasts
      class MainContent < ::Views::Base
        def initialize(payment_reminders:, paid_status:, section_spending:)
          @payment_reminders = payment_reminders
          @paid_status = paid_status || {}
          @section_spending = section_spending
        end

        def view_template
          div(id: "forecast_main_content", class: "space-y-6") do
            render_upcoming_payments_section
            render ::Views::Banking::Forecasts::SpendingLimitsSection.new(
              section_spending: @section_spending
            )
          end
        end

        private

        def render_upcoming_payments_section
          monthly_data = calculate_monthly_data
          # Calculate totals excluding paid reminders
          unpaid_reminders = @payment_reminders.reject { |r| paid?(r) }
          total_upcoming = unpaid_reminders.sum { |r| r.expected_amount || 0 }
          next_payment = unpaid_reminders.min_by(&:cutoff_date)

          div(class: "rounded-lg border bg-card shadow-sm") do
            div(class: "flex items-center justify-between p-4 border-b") do
              div(class: "flex items-center gap-3") do
                render ::Components::Icon::CreditCard.new(size: "20", class: "text-muted-foreground")
                h2(class: "font-semibold") { "Payment Reminders" }
              end
            end

            # Summary stats
            div(class: "p-4 border-b bg-muted/30") do
              div(class: "grid grid-cols-2 gap-4") do
                div do
                  div(class: "text-xs text-muted-foreground mb-1") { "Total Upcoming" }
                  div(class: "text-lg font-semibold") { format_currency(total_upcoming) }
                end
                if next_payment
                  div do
                    div(class: "text-xs text-muted-foreground mb-1") { "Next Payment" }
                    div(class: "text-lg font-semibold") do
                      if next_payment.cutoff_date < Date.current
                        span(class: "text-red-600 dark:text-red-400") { "Overdue" }
                      elsif next_payment.cutoff_date == Date.current
                        span(class: "text-amber-600 dark:text-amber-400") { "Due Today" }
                      else
                        days = (next_payment.cutoff_date - Date.current).to_i
                        plain "In #{days} #{days == 1 ? 'day' : 'days'}"
                      end
                    end
                  end
                end
              end
            end

            # Monthly breakdown chart
            div(class: "p-4 border-b") do
              render_monthly_chart(monthly_data)
            end

            # Payment reminders management interface
            div(class: "p-4") do
              render_reminders_tabs
              render_add_reminder_button
            end
          end
        end

        def render_reminders_tabs
          all_reminders = view_context.current_user.payment_reminders.order(cutoff_date: :asc)

          div(data: { controller: "tabs" }) do
            div(class: "flex gap-2 mb-4") do
              render_tab_button("active", "Active", true)
              render_tab_button("upcoming", "Upcoming", false)
              render_tab_button("inactive", "Inactive", false)
            end

            render_tab_panel("active", all_reminders.select(&:active?), true)
            render_tab_panel("upcoming", all_reminders.select { |r| r.active? && r.cutoff_date <= Date.current + 7.days && r.cutoff_date >= Date.current }, false)
            render_tab_panel("inactive", all_reminders.reject(&:active?), false)
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
              render_tab_empty_state(id)
            else
              div(class: "space-y-2 max-h-96 overflow-y-auto") do
                reminders.each do |reminder|
                  render ::Views::Banking::PaymentReminders::ReminderRow.new(payment_reminder: reminder)
                end
              end
            end
          end
        end

        def render_tab_empty_state(type)
          message = case type
          when "active" then "No active payment reminders"
          when "upcoming" then "No reminders due in the next 7 days"
          when "inactive" then "No inactive reminders"
          else "No reminders"
          end

          div(class: "text-center py-8") do
            render ::Components::Icon::CreditCard.new(size: "32", class: "mx-auto text-muted-foreground mb-3")
            p(class: "text-sm text-muted-foreground") { message }
          end
        end

        def render_add_reminder_button
          div(class: "mt-4") do
            button(
              type: "button",
              class: "w-full inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-dashed border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2",
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

        def calculate_monthly_data
          months = (0..5).map { |i| (Date.current + i.months).beginning_of_month }

          months.map do |month|
            month_end = month.end_of_month
            reminders = @payment_reminders.select { |r| r.cutoff_date >= month && r.cutoff_date <= month_end }
            # Separate paid and unpaid
            unpaid_reminders = reminders.reject { |r| paid?(r) }
            paid_reminders = reminders.select { |r| paid?(r) }
            total = unpaid_reminders.sum { |r| r.expected_amount || 0 }
            paid_total = paid_reminders.sum { |r| r.expected_amount || 0 }
            count = reminders.size # Show total count including paid
            paid_count = reminders.count { |r| paid?(r) }

            { month: month, total: total, paid_total: paid_total, count: count, paid_count: paid_count }
          end
        end

        def chart_data_for_monthly(monthly_data)
          {
            labels: monthly_data.map { |d| d[:month].strftime("%b") },
            unpaid: monthly_data.map { |d| d[:total] || 0 },
            paid: monthly_data.map { |d| d[:paid_total] || 0 }
          }
        end

        def render_monthly_chart(monthly_data)
          chart_data = chart_data_for_monthly(monthly_data)

          div(
            class: "h-64",
            data: {
              controller: "monthly-payments-chart",
              monthly_payments_chart_data_value: chart_data.to_json
            }
          ) do
            canvas(data: { monthly_payments_chart_target: "canvas" })
          end
        end

        def paid?(reminder)
          @paid_status.key?(reminder.id) && @paid_status[reminder.id].present?
        end

        def format_currency(amount)
          "#{view_context.number_with_delimiter(sprintf('%.2f', amount))}"
        end
      end
    end
  end
end
