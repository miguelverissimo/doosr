# frozen_string_literal: true

module Views
  module Items
    class DeferOptions < ::Views::Base
      def initialize(item:, day: nil)
        @item = item
        @day = day
      end

      def view_template
        # Just render the content that goes inside the existing sheet
        div(id: "sheet_content_area", data: { controller: "defer-date-picker" }) do
          SheetHeader do
            SheetTitle(class: "text-left") { "Defer Item" }
            SheetDescription(class: "text-left text-xs text-muted-foreground") do
              @item.title
            end
          end

          SheetMiddle(class: "py-4") do
            # Defer options view
            div(id: "defer_options_view", class: "flex flex-col gap-3") do
              render_defer_option(
                "Tomorrow",
                "tomorrow",
                ::Item.get_tomorrow_date
              )

              render_defer_option(
                "Next Monday",
                "next_monday",
                ::Item.get_next_monday_date
              )

              render_defer_option(
                "Next Month",
                "next_month",
                ::Item.get_next_month_first_date
              )

              # Custom date picker button
              form(
                action: defer_item_path(@item),
                method: "post",
                data: { turbo: "true" },
                class: "block"
              ) do
                csrf_token_field
                input(type: "hidden", name: "_method", value: "patch")
                input(type: "hidden", name: "item_id", value: @item.id)
                input(type: "hidden", name: "day_id", value: @day&.id)

                button(
                  type: "button",
                  class: "w-full flex items-center justify-between rounded-lg border bg-card p-4 hover:bg-accent transition-colors",
                  data: {
                    controller: "defer-date-picker",
                    action: "click->defer-date-picker#open"
                  }
                ) do
                  div(class: "flex flex-col items-start") do
                    p(class: "font-medium text-sm") { "Pick on Calendar" }
                    p(class: "text-xs text-muted-foreground") { "Choose a custom date" }
                  end

                  # Calendar icon
                  svg(
                    xmlns: "http://www.w3.org/2000/svg",
                    width: "20",
                    height: "20",
                    viewBox: "0 0 24 24",
                    fill: "none",
                    stroke: "currentColor",
                    stroke_width: "2",
                    stroke_linecap: "round",
                    stroke_linejoin: "round",
                    class: "text-muted-foreground"
                  ) do |s|
                    s.rect(x: "3", y: "4", width: "18", height: "18", rx: "2", ry: "2")
                    s.line(x1: "16", y1: "2", x2: "16", y2: "6")
                    s.line(x1: "8", y1: "2", x2: "8", y2: "6")
                    s.line(x1: "3", y1: "10", x2: "21", y2: "10")
                  end
                end
              end
            end

            # Calendar view (hidden by default)
            div(id: "defer_calendar_view", class: "hidden") do
              # Hidden form for calendar to use
              form(
                id: "defer_calendar_form",
                action: defer_item_path(@item),
                method: "post",
                data: { turbo: "true" },
                class: "hidden"
              ) do
                csrf_token_field
                input(type: "hidden", name: "_method", value: "patch")
                input(type: "hidden", name: "item_id", value: @item.id)
                input(type: "hidden", name: "day_id", value: @day&.id)
              end

              # Calendar on left, buttons on right
              div(
                class: "flex gap-4",
                data: {
                  controller: "defer-calendar",
                  defer_calendar_item_id_value: @item.id,
                  defer_calendar_day_id_value: @day&.id
                }
              ) do
                # Calendar on the left
                div(class: "flex-shrink-0") do
                  Calendar(selected_date: Date.tomorrow)
                end

                # Buttons on the right
                div(class: "flex flex-col gap-3 justify-center flex-1") do
                  button(
                    type: "button",
                    disabled: true,
                    class: "w-full h-12 px-4 py-2 bg-primary text-primary-foreground hover:bg-primary/90 rounded-md font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed",
                    data: {
                      action: "click->defer-calendar#confirm",
                      defer_calendar_target: "confirmButton"
                    }
                  ) do
                    span(data: { defer_calendar_target: "buttonText" }) { "Select a date" }
                  end

                  button(
                    type: "button",
                    class: "w-full h-12 px-4 py-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground rounded-md font-medium transition-colors",
                    data: { action: "click->defer-date-picker#showOptions" }
                  ) do
                    "Cancel"
                  end
                end
              end
            end
          end
        end
      end

      private

      def render_defer_option(label, value, date)
        form(
          action: defer_item_path(@item),
          method: "post",
          data: { turbo: "true" },
          class: "block"
        ) do
          csrf_token_field
          input(type: "hidden", name: "_method", value: "patch")
          input(type: "hidden", name: "target_date", value: value)
          input(type: "hidden", name: "day_id", value: @day&.id)

          button(
            type: "submit",
            class: "w-full flex items-center justify-between rounded-lg border bg-card p-4 hover:bg-accent transition-colors"
          ) do
            div(class: "flex flex-col items-start") do
              p(class: "font-medium text-sm") { label }
              p(class: "text-xs text-muted-foreground") do
                format_defer_date(date)
              end
            end

            # Arrow icon
            svg(
              xmlns: "http://www.w3.org/2000/svg",
              width: "20",
              height: "20",
              viewBox: "0 0 24 24",
              fill: "none",
              stroke: "currentColor",
              stroke_width: "2",
              stroke_linecap: "round",
              stroke_linejoin: "round",
              class: "text-muted-foreground"
            ) do |s|
              s.polyline(points: "9 18 15 12 9 6")
            end
          end
        end
      end

      def format_defer_date(date)
        date.strftime("%a, %b %-d")
      end
    end
  end
end
