# frozen_string_literal: true

module Views
  module Days
    class Show < ::Views::Base
      def initialize(day:, date:, is_today:, all_items: nil, active_items: nil, inactive_items: nil, all_lists: nil, active_lists: nil, inactive_lists: nil)
        @day = day
        @date = date
        @is_today = is_today
        @all_items = all_items || []
        @active_items = active_items || []
        @inactive_items = inactive_items || []
        @all_lists = all_lists || []
        @active_lists = active_lists || []
        @inactive_lists = inactive_lists || []
      end

      def view_template
        div(
          class: "flex h-full w-full flex-col min-w-0 max-w-full overflow-x-hidden",
          style: "max-width: 100%; overflow-x: hidden; width: 100%;",
          data: @day ? { controller: "day-move", day_move_day_id_value: @day.id } : {}
        ) do
          # Cancel button for moving mode (hidden by default)
          unless @day&.closed?
            div(
              data: { day_move_target: "cancelButton" },
              class: "hidden mb-3"
            ) do
              Button(variant: :outline, size: :sm, data: { action: "click->day-move#cancelMoving" }) do
                "Cancel Move"
              end
            end
          end

          # Content - no header needed, date is in top bar
          div(id: "day_content", class: "flex-1 w-full min-w-0 max-w-full") do
            render_day_content
          end
        end
      end

      private

      def render_day_content
        div(class: "space-y-3 w-full min-w-0 max-w-full") do
          # Error container for form errors
          div(id: "item_form_errors")

          # Mobile actions row
          div(class: "block md:hidden") do
            render ::Views::Days::Mobile::ActionsRow.new(day: @day)
          end

          # Desktop actions row
          div(class: "hidden md:block") do
            render ::Views::Days::ActionsRow.new(day: @day)
          end

          # Root target for moving items (hidden by default) - BELOW input, ABOVE items
          div(
            data: { day_move_target: "rootTarget", action: "click->day-move#selectRootTarget" },
            class: "hidden rounded-lg border-2 border-dashed border-primary bg-primary/5 p-4 text-center cursor-pointer hover:bg-primary/10 transition-colors"
          ) do
            p(class: "text-sm font-medium") { "Drop here" }
          end

          # Items list
          div(id: "items_list", class: "space-y-2 mt-3 w-full min-w-0 max-w-full overflow-x-hidden", style: "max-width: 100%; overflow-x: hidden;", data: { controller: "item-highlight" }) do
            # Render existing items and lists if any
            if @day
              # Build tree to get items and lists in proper order
              tree = ItemTree::Build.call(@day.descendant, root_label: "day")

              # Render all children (items and list links)
              tree.children.each do |node|
                render ::Views::Items::TreeNode.new(node: node, day: @day)
              end
            else
              # Day doesn't exist yet - show message
              div(class: "text-sm text-muted-foreground text-center py-8") do
                p { "This day hasn't been opened yet. Add an item or open the day to get started." }
              end
            end
          end

          # Item actions sheet container (rendered dynamically via Turbo Stream)
          div(id: "actions_sheet")
        end
      end
    end
  end
end
