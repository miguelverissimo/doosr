# frozen_string_literal: true

module Views
  module DayPaymentReminders
    class PaymentReminderItem < ::Views::Base
      def initialize(day_payment_reminder:, day: nil, list: nil, is_public_list: false)
        @day_payment_reminder = day_payment_reminder
        @day = day
        @list = list
        @is_public_list = is_public_list
      end

      def view_template
        controller_data = {
          controller: "day-payment-reminder",
          day_payment_reminder_id_value: @day_payment_reminder.id,
          action: "click->day-payment-reminder#openActions"
        }
        controller_data[:day_payment_reminder_day_id_value] = @day.id if @day
        controller_data[:day_payment_reminder_list_id_value] = @list.id if @list

        div(
          id: "day_payment_reminder_#{@day_payment_reminder.id}",
          class: item_classes,
          data: controller_data
        ) do
          render_credit_card_icon
          render_content
          render_amount
          render_link_button if @day_payment_reminder.payment_url.present? && !@day_payment_reminder.paid?
        end
      end

      private

      def item_classes
        base = "group flex items-center gap-2 rounded-lg border p-2.5 transition-colors cursor-pointer w-full"
        colors = row_color_classes
        opacity = @day_payment_reminder.paid? ? " opacity-60" : ""
        "#{base} #{colors}#{opacity}"
      end

      def row_color_classes
        return "bg-green-50 dark:bg-green-900/20 hover:bg-green-100 dark:hover:bg-green-900/30 border-green-200 dark:border-green-800" if @day_payment_reminder.paid?

        days_until = @day_payment_reminder.days_until_cutoff
        if days_until <= 1
          "bg-red-50 dark:bg-red-900/20 hover:bg-red-100 dark:hover:bg-red-900/30 border-red-200 dark:border-red-800"
        elsif days_until <= 3
          "bg-orange-50 dark:bg-yellow-900/20 hover:bg-yellow-100 dark:hover:bg-yellow-900/30 border-yellow-200 dark:border-yellow-800"
        else
          "bg-blue-50 dark:bg-blue-900/20 hover:bg-blue-100 dark:hover:bg-blue-900/30 border-blue-200 dark:border-blue-800"
        end
      end

      def icon_color_class
        return "text-green-600 dark:text-green-400" if @day_payment_reminder.paid?

        days_until = @day_payment_reminder.days_until_cutoff
        if days_until <= 1
          "text-red-600 dark:text-red-400"
        elsif days_until <= 3
          "text-yellow-600 dark:text-yellow-400"
        else
          "text-blue-600 dark:text-blue-400"
        end
      end

      def render_credit_card_icon
        div(class: "shrink-0") do
          if @day_payment_reminder.paid?
            render ::Components::Icon::CheckCircle.new(size: "16", class: icon_color_class)
          else
            render ::Components::Icon::CreditCard.new(size: "16", class: icon_color_class)
          end
        end
      end

      def render_content
        div(class: "flex-1 min-w-0") do
          div(class: "truncate") do
            title_classes = ["text-sm font-medium truncate"]
            title_classes << "line-through text-muted-foreground" if @day_payment_reminder.paid?
            p(class: title_classes.join(" ")) do
              plain @day_payment_reminder.title
              if @day_payment_reminder.paid?
                span(class: "ml-2 text-xs text-green-600 dark:text-green-400") { "(Paid)" }
              end
            end
          end
          div(class: "text-xs text-muted-foreground truncate") { details_text }
        end
      end

      def render_amount
        return unless @day_payment_reminder.expected_amount.present? && @day_payment_reminder.expected_amount > 0

        div(class: "flex items-center gap-3 shrink-0 ml-auto") do
          amount_classes = ["font-mono font-medium text-sm"]
          amount_classes << "text-muted-foreground line-through" if @day_payment_reminder.paid?
          span(class: amount_classes.join(" ")) do
            plain format_currency(@day_payment_reminder.expected_amount)
          end
        end
      end

      def render_link_button
        div(class: "shrink-0") do
          render ::Components::ColoredLink.new(
            href: @day_payment_reminder.payment_url,
            variant: :ghost,
            size: :sm,
            target: "_blank",
            rel: "noopener noreferrer",
            class: "p-1 rounded hover:bg-black/10 dark:hover:bg-white/10",
            title: "Open payment page",
            icon: true,
            data: { action: "click->day-payment-reminder#stopPropagation" }
          ) do
            render ::Components::Icon::ExternalLink.new(size: "16", class: icon_color_class)
          end
        end
      end

      def details_text
        cutoff_date = @day_payment_reminder.cutoff_date
        days_until = @day_payment_reminder.days_until_cutoff
        return "" unless cutoff_date.present?

        date_str = "Due: #{format_date(cutoff_date)}"
        urgency = case days_until
        when 0 then "TODAY"
        when 1 then "Tomorrow"
        else "#{days_until} days left"
        end

        "#{date_str}   #{urgency}"
      end

      def format_date(date)
        date.year == Date.current.year ? date.strftime("%b %d") : date.strftime("%b %d, %Y")
      end

      def format_currency(amount)
        "#{view_context.number_with_delimiter(sprintf('%.2f', amount))}"
      end
    end
  end
end
