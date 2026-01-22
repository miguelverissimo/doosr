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
            # Two main features side by side
            div(class: "grid gap-6 lg:grid-cols-2") do
              render_upcoming_payments_section
              render ::Views::Banking::Forecasts::SpendingLimitsSection.new(
                section_spending: @section_spending
              )
            end
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
                h2(class: "font-semibold") { "Upcoming Payments" }
              end
              button(
                type: "button",
                class: "text-sm text-muted-foreground hover:text-foreground",
                data: {
                  controller: "enable-dialog",
                  enable_dialog_url_value: view_context.banking_payment_reminders_path,
                  action: "click->enable-dialog#openDialog"
                }
              ) { "Manage" }
            end

            if @payment_reminders.empty?
              render_empty_payments_state
            else
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

              # Payments list
              div(class: "divide-y max-h-96 overflow-y-auto") do
                @payment_reminders.sort_by(&:cutoff_date).each do |reminder|
                  render_payment_item(reminder)
                end
              end
            end
          end
        end

        def render_empty_payments_state
          div(class: "p-8 text-center") do
            render ::Components::Icon::CreditCard.new(size: "32", class: "mx-auto mb-3 text-muted-foreground")
            p(class: "text-sm font-medium mb-1") { "No upcoming payments" }
            p(class: "text-xs text-muted-foreground mb-4") do
              plain "Add payment reminders to track upcoming bills and expenses."
            end
            button(
              type: "button",
              class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4",
              data: {
                controller: "enable-dialog",
                enable_dialog_url_value: view_context.banking_payment_reminders_path,
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

        def render_payment_item(reminder)
          is_paid = paid?(reminder)
          is_overdue = reminder.cutoff_date < Date.current && !is_paid
          is_soon = reminder.cutoff_date <= Date.current + 7.days && !is_overdue && !is_paid

          item_classes = "flex items-center justify-between px-4 py-3 hover:bg-muted/50"
          item_classes += " opacity-60" if is_paid

          div(class: item_classes) do
            div(class: "flex items-center gap-3 min-w-0") do
              # Status indicator dot
              if is_paid
                render ::Components::Icon::CheckCircle.new(size: "16", class: "text-green-600 dark:text-green-400 shrink-0")
              elsif is_overdue
                div(class: "w-2 h-2 rounded-full bg-red-500 shrink-0")
              elsif is_soon
                div(class: "w-2 h-2 rounded-full bg-amber-500 shrink-0")
              else
                div(class: "w-2 h-2 rounded-full bg-muted-foreground/30 shrink-0")
              end

              div(class: "min-w-0") do
                title_classes = ["font-medium truncate"]
                title_classes << "line-through text-muted-foreground" if is_paid
                div(class: title_classes.join(" ")) do
                  plain reminder.title
                  if is_paid
                    span(class: "ml-2 text-xs text-green-600 dark:text-green-400") { "(Paid)" }
                  end
                end
                span(class: "text-sm text-muted-foreground") do
                  if is_paid
                    paid_at = @paid_status[reminder.id]
                    if paid_at
                      plain "Paid: #{format_datetime(paid_at)}"
                    else
                      plain "Paid"
                    end
                  elsif is_overdue
                    plain "Overdue #{reminder.cutoff_date.strftime('%b %d')}"
                  else
                    plain reminder.cutoff_date.strftime("%b %d")
                  end
                end
              end
            end

            div(class: "flex items-center gap-3 shrink-0") do
              if reminder.expected_amount.present? && reminder.expected_amount > 0
                amount_classes = ["font-mono font-medium"]
                amount_classes << "text-muted-foreground line-through" if is_paid
                span(class: amount_classes.join(" ")) do
                  plain format_currency(reminder.expected_amount)
                end
              end
              if reminder.payment_url.present? && !is_paid
                a(
                  href: reminder.payment_url,
                  target: "_blank",
                  rel: "noopener noreferrer",
                  class: "text-primary hover:text-primary/80 text-sm font-medium"
                ) do
                  render ::Components::Icon::ExternalLink.new(size: "16")
                end
              end
            end
          end
        end

        def paid?(reminder)
          @paid_status.key?(reminder.id) && @paid_status[reminder.id].present?
        end

        def format_datetime(datetime)
          datetime.strftime("%b %d, %Y at %l:%M %p")
        end

        def format_currency(amount)
          "#{view_context.number_with_delimiter(sprintf('%.2f', amount))}"
        end
      end
    end
  end
end
