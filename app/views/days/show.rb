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
          class: "flex h-full flex-col",
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
          div(id: "day_content", class: "flex-1") do
            render_day_content
          end
        end
      end

      private

      def render_day_content
        div(class: "space-y-3") do
          # Error container for form errors
          div(id: "item_form_errors")

          render ::Views::Days::ActionsRow.new(day: @day)

          # Root target for moving items (hidden by default) - BELOW input, ABOVE items
          div(
            data: { day_move_target: "rootTarget", action: "click->day-move#selectRootTarget" },
            class: "hidden rounded-lg border-2 border-dashed border-primary bg-primary/5 p-4 text-center cursor-pointer hover:bg-primary/10 transition-colors"
          ) do
            p(class: "text-sm font-medium") { "Drop here" }
          end

          # Items list
          div(id: "items_list", class: "space-y-2 mt-3") do
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
          div(id: "item_actions_sheet")
        end
      end
    end
  end
end
