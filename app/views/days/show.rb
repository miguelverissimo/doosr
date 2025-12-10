# frozen_string_literal: true

module Views
  module Days
    class Show < Views::Base
      def initialize(day:, date:, is_today:, all_items: nil, active_items: nil, inactive_items: nil)
        @day = day
        @date = date
        @is_today = is_today
        @all_items = all_items || []
        @active_items = active_items || []
        @inactive_items = inactive_items || []
      end

      def view_template
        div(class: "flex h-full flex-col") do
          # Content - no header needed, date is in top bar
          div(class: "flex-1") do
            render_day_content
          end
        end
      end

      private

      def render_day_content
        div(class: "space-y-3") do
          # Error container for form errors
          div(id: "item_form_errors")

          # Add item form - only show if day is not closed
          unless @day&.closed?
            form(
              action: items_path,
              method: "post",
              data: {
                controller: "item-form",
                action: "submit->item-form#submit turbo:submit-end->item-form#clearForm",
                turbo: "true"
              },
              class: "flex items-center gap-2"
            ) do
              csrf_token_field
              if @day
                input(type: "hidden", name: "day_id", value: @day.id)
              else
                input(type: "hidden", name: "date", value: @date.to_s)
              end
              input(
                type: "hidden",
                name: "item[item_type]",
                value: "completable",
                data: { item_form_target: "itemType" }
              )

              Input(
                type: "text",
                name: "item[title]",
                placeholder: "Add an item...",
                class: "flex-1 text-sm h-9",
                data: { item_form_target: "titleInput" },
                required: true
              )

              # Type selector button (completable by default)
              Button(
                type: :button,
                variant: :ghost,
                icon: true,
                size: :sm,
                class: "shrink-0 h-9 w-9",
                data: { action: "click->item-form#cycleType" }
              ) do
                svg(
                  xmlns: "http://www.w3.org/2000/svg",
                  class: "h-4 w-4",
                  viewBox: "0 0 24 24",
                  fill: "none",
                  stroke: "currentColor",
                  stroke_width: "2",
                  data: { item_form_target: "typeIcon" }
                ) do |s|
                  s.circle(cx: "12", cy: "12", r: "10")
                end
              end

              # Submit button
              Button(type: :submit, variant: :ghost, icon: true, size: :sm, class: "shrink-0 h-9 w-9") do
                svg(
                  xmlns: "http://www.w3.org/2000/svg",
                  class: "h-4 w-4",
                  viewBox: "0 0 24 24",
                  fill: "none",
                  stroke: "currentColor",
                  stroke_width: "2"
                ) do |s|
                  s.line(x1: "12", y1: "5", x2: "12", y2: "19")
                  s.line(x1: "5", y1: "12", x2: "19", y2: "12")
                end
              end
            end
          end

          # Root target for moving items (hidden by default) - BELOW input, ABOVE items
          div(
            data: { day_move_target: "rootTarget", action: "click->day-move#selectRootTarget" },
            class: "hidden rounded-lg border-2 border-dashed border-primary bg-primary/5 p-4 text-center cursor-pointer hover:bg-primary/10 transition-colors"
          ) do
            p(class: "text-sm font-medium") { "Drop here" }
          end

          # Items list
          div(id: "items_list", class: "space-y-2 mt-3") do
            # Render existing items if any
            if @day
              # Render active items first
              @active_items.each do |item|
                # Use nested rendering to show items with their children
                render Views::Items::ItemWithChildren.new(item: item, day: @day)
              end

              # Render inactive items after (done, dropped, deferred)
              @inactive_items.each do |item|
                # Use nested rendering to show items with their children
                render Views::Items::ItemWithChildren.new(item: item, day: @day)
              end
            else
              # Day doesn't exist yet - show message
              div(class: "text-sm text-muted-foreground text-center py-8") do
                p { "This day hasn't been opened yet. Add an item or open the day to get started." }
              end
            end
          end

          # Item actions sheet container (rendered dynamically via Turbo Stream)
          div(id: "item_actions_sheet")
        end
      end
    end
  end
end
