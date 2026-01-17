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
            div(id: "defer_options_view", class: "flex flex-col gap-4") do
              # Options row - all on one line
              div(class: "flex gap-2") do
                render_defer_option("Tomorrow", "tomorrow", ::Item.get_tomorrow_date)
                render_defer_option("Next Monday", "next_monday", ::Item.get_next_monday_date)
                render_defer_option("Next Month", "next_month", ::Item.get_next_month_first_date)
                render_calendar_option
              end

              # Cancel button
              div(class: "flex justify-center items-center gap-3 mt-4") do
                Button(
                  type: :button,
                  variant: :outline,
                  data: {
                    controller: "drawer-back",
                    drawer_back_url_value: actions_sheet_item_path(@item, day_id: @day&.id, from_edit_form: true),
                    action: "click->drawer-back#goBack"
                  }
                ) { "Cancel" }
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

              # Calendar and buttons stacked
              div(
                class: "flex flex-col gap-4",
                data: {
                  controller: "defer-calendar",
                  defer_calendar_item_id_value: @item.id,
                  defer_calendar_day_id_value: @day&.id
                }
              ) do
                # Calendar centered
                div(class: "flex justify-center") do
                  Calendar(selected_date: Date.tomorrow)
                end

                # Buttons centered below
                div(class: "flex justify-center items-center gap-3") do
                  Button(
                    type: :button,
                    variant: :primary,
                    disabled: true,
                    data: {
                      action: "click->defer-calendar#confirm",
                      defer_calendar_target: "confirmButton"
                    }
                  ) do
                    span(data: { defer_calendar_target: "buttonText" }) { "Select a date" }
                  end

                  Button(
                    type: :button,
                    variant: :outline,
                    data: { action: "click->defer-date-picker#showOptions" }
                  ) { "Cancel" }
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
          class: "flex-1"
        ) do
          csrf_token_field
          input(type: "hidden", name: "_method", value: "patch")
          input(type: "hidden", name: "target_date", value: value)
          input(type: "hidden", name: "day_id", value: @day&.id)

          button(
            type: "submit",
            class: "w-full flex flex-col items-center justify-center rounded-lg border bg-card p-3 hover:bg-accent transition-colors"
          ) do
            p(class: "font-medium text-sm") { label }
            p(class: "text-xs text-muted-foreground") { date.strftime("%a, %b %-d") }
          end
        end
      end

      def render_calendar_option
        div(class: "flex-1") do
          button(
            type: "button",
            class: "w-full flex flex-col items-center justify-center rounded-lg border bg-card p-3 hover:bg-accent transition-colors",
            data: { action: "click->defer-date-picker#open" }
          ) do
            p(class: "font-medium text-sm") { "Calendar" }
            p(class: "text-xs text-muted-foreground") { "Pick a date" }
          end
        end
      end
    end
  end
end
