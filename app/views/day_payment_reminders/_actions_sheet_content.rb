# frozen_string_literal: true

module Views
  module DayPaymentReminders
    class ActionsSheetContent < ::Views::Base
      def initialize(day_payment_reminder:, day: nil, list: nil, reminder_index: nil, total_reminders: nil)
        @day_payment_reminder = day_payment_reminder
        @day = day
        @list = list
        @reminder_index = reminder_index
        @total_reminders = total_reminders
        @day_is_closed = @day&.closed? || false
      end

      def view_template
        div(id: "sheet_content_area") do
          SheetHeader do
            SheetTitle(class: "text-left") do
              plain @day_payment_reminder.title
              if @day_payment_reminder.paid?
                span(class: "ml-2 text-sm text-green-600 dark:text-green-400 font-normal") { "(Paid)" }
              end
            end
            SheetDescription(class: "text-left text-xs text-muted-foreground") do
              div do
                plain "Due: #{format_date(@day_payment_reminder.cutoff_date)}"
                if @day_payment_reminder.expected_amount.present?
                  plain " • "
                  plain format_currency(@day_payment_reminder.expected_amount)
                end
                if @day_payment_reminder.paid?
                  plain " • "
                  plain "Paid: #{format_datetime(@day_payment_reminder.paid_at)}"
                end
              end
            end
          end

          SheetMiddle(class: "py-4 space-y-4") do
            # Payment details
            div(class: "space-y-2") do
              div(class: "flex items-center justify-between text-sm") do
                span(class: "text-muted-foreground") { "Days until due:" }
                span(class: "font-medium") do
                  days = @day_payment_reminder.days_until_cutoff
                  if days < 0
                    span(class: "text-red-600 dark:text-red-400") { "#{days.abs} days overdue" }
                  elsif days == 0
                    span(class: "text-red-600 dark:text-red-400") { "Due today" }
                  else
                    plain "#{days} #{days == 1 ? 'day' : 'days'}"
                  end
                end
              end

              if @day_payment_reminder.payment_url.present?
                div(class: "flex items-center justify-between text-sm") do
                  span(class: "text-muted-foreground") { "Payment URL:" }
                  a(
                    href: @day_payment_reminder.payment_url,
                    target: "_blank",
                    rel: "noopener noreferrer",
                    class: "text-primary hover:underline font-medium"
                  ) do
                    render ::Components::Icon::ExternalLink.new(size: "14", class: "inline mr-1")
                    plain "Open"
                  end
                end
              end
            end

            # Action buttons
            render ::Views::DayPaymentReminders::ActionsSheetButtons.new(
              day_payment_reminder: @day_payment_reminder,
              day: @day,
              list: @list,
              reminder_index: @reminder_index,
              total_reminders: @total_reminders,
              day_is_closed: @day_is_closed
            )
          end
        end
      end

      private

      def format_date(date)
        date.year == Date.current.year ? date.strftime("%b %d") : date.strftime("%b %d, %Y")
      end

      def format_currency(amount)
        "#{view_context.number_with_delimiter(sprintf('%.2f', amount))}"
      end

      def format_datetime(datetime)
        datetime.strftime("%b %d, %Y at %l:%M %p")
      end
    end
  end
end
