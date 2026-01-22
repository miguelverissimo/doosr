# frozen_string_literal: true

module Views
  module Items
    class PaymentReminderItem < BaseItem
      def view_template
        div(
          id: container_id,
          class: item_classes,
          data: stimulus_data
        ) do
          render_checkbox
          render_credit_card_icon
          render_content
          render_link_button if payment_url.present?
        end
      end

      def item_classes
        base = "group flex items-center gap-2 rounded-lg border p-2.5 transition-colors cursor-pointer w-full"
        colors = row_color_classes
        opacity = @record.done? ? " opacity-60" : ""
        "#{base} #{colors}#{opacity}"
      end

      def stimulus_data
        {
          controller: "item",
          item_id_value: @record.id,
          item_day_id_value: @day&.id,
          item_list_id_value: @list&.id,
          item_is_public_list_value: @is_public_list,
          item_type_value: @record.item_type,
          action: "click->item#openSheet",
          day_move_target: "item"
        }
      end

      private

      def render_checkbox
        toggle_path = @list ? toggle_state_reusable_item_path(@record) : toggle_state_item_path(@record)

        form(
          action: toggle_path,
          method: "post",
          data: {
            controller: "form-loading item",
            form_loading_message_value: @record.done? ? "Marking as todo..." : "Marking as done...",
            turbo_frame: "_top",
            action: "click->item#stopPropagation change->item#submitForm"
          },
          class: "shrink-0"
        ) do
          csrf_token_field
          input(type: "hidden", name: "_method", value: "patch")
          input(type: "hidden", name: "state", value: @record.done? ? "todo" : "done")
          input(type: "hidden", name: "list_id", value: @list.id) if @list

          label(class: "relative inline-flex items-center cursor-pointer shrink-0") do
            input(type: "checkbox", checked: @record.done?, class: "sr-only peer")
            div(class: "h-4 w-4 rounded-sm border border-primary bg-background peer-checked:bg-primary peer-checked:border-primary peer-disabled:opacity-50 peer-disabled:cursor-not-allowed peer-focus-visible:ring-2 peer-focus-visible:ring-ring peer-focus-visible:ring-offset-2 flex items-center justify-center transition-colors") do
              render ::Components::Icon::Check.new(size: "12", class: "h-3 w-3 text-primary-foreground", stroke_width: "3") if @record.done?
            end
          end
        end
      end

      def render_credit_card_icon
        div(class: "shrink-0") do
          render ::Components::Icon::CreditCard.new(size: "16", class: icon_color_class)
        end
      end

      def render_content
        div(class: "flex-1 min-w-0") do
          div(class: "truncate") do
            title_classes = [ "text-sm truncate" ]
            title_classes << "line-through text-muted-foreground" if @record.done?
            p(class: title_classes.join(" ")) { payment_title }
          end
          div(class: "text-xs text-muted-foreground truncate") { details_text }
        end
      end

      def render_link_button
        div(class: "shrink-0 ml-auto") do
          render ::Components::ColoredLink.new(
            href: payment_url,
            variant: :ghost,
            size: :sm,
            target: "_blank",
            rel: "noopener noreferrer",
            class: "p-1 rounded hover:bg-black/10 dark:hover:bg-white/10",
            title: "Open payment page",
            icon: true,
            data: { action: "click->item#stopPropagation" }
          ) do
            render ::Components::Icon::ExternalLink.new(size: "16", class: icon_color_class)
          end
        end
      end

      def row_color_classes
        days_until = @record.extra_data&.dig("days_until_cutoff").to_i
        if days_until <= 1
          "bg-red-50 dark:bg-red-900/20 hover:bg-red-100 dark:hover:bg-red-900/30 border-red-200 dark:border-red-800"
        elsif days_until <= 3
          "bg-orange-50 dark:bg-yellow-900/20 hover:bg-yellow-100 dark:hover:bg-yellow-900/30 border-yellow-200 dark:border-yellow-800"
        else
          "bg-blue-50 dark:bg-blue-900/20 hover:bg-blue-100 dark:hover:bg-blue-900/30 border-blue-200 dark:border-blue-800"
        end
      end

      def icon_color_class
        days_until = @record.extra_data&.dig("days_until_cutoff").to_i
        if days_until <= 1
          "text-red-600 dark:text-red-400"
        elsif days_until <= 3
          "text-yellow-600 dark:text-yellow-400"
        else
          "text-blue-600 dark:text-blue-400"
        end
      end

      def payment_title
        @record.extra_data&.dig("payment_reminder_title") || @record.title
      end

      def details_text
        cutoff_date = @record.extra_data&.dig("cutoff_date")
        days_until = @record.extra_data&.dig("days_until_cutoff").to_i
        return "" unless cutoff_date.present?

        date_str = "Due: #{format_date(Date.parse(cutoff_date))}"
        urgency = case days_until
        when 0 then "TODAY"
        when 1 then "Tomorrow"
        else "#{days_until} days left"
        end

        "#{date_str}   #{urgency}"
      end

      def payment_url
        url = @record.extra_data&.dig("payment_url")
        url.presence
      end

      def format_date(date)
        date.year == Date.current.year ? date.strftime("%b %d") : date.strftime("%b %d, %Y")
      end
    end
  end
end
