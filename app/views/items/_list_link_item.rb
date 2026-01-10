# frozen_string_literal: true

module Views
  module Items
    class ListLinkItem < BaseItem
      def item_classes
        "group flex items-center gap-2 rounded-lg border border-blue-500/30 bg-blue-50 dark:bg-blue-950/20 p-2.5 hover:bg-blue-100 dark:hover:bg-blue-950/30 transition-colors cursor-pointer"
      end

      def render_icon
        # Link icon - navigates to the list
        a(
          href: list_path(@record),
          data: {
            turbo: false,
            action: "click->list-link#navigateToList"
          },
          class: "shrink-0"
        ) do
          render ::Components::Icon::Link.new(size: "16", class: "text-blue-600 dark:text-blue-400")
        end
      end

      def render_content
        # Wrapper takes flex space, but title link is only as wide as text
        div(class: "flex-1 min-w-0") do
          a(
            href: list_path(@record),
            data: {
              turbo: false,
              action: "click->list-link#navigateToList"
            },
            class: "inline-block"
          ) do
            span(class: "text-sm font-medium text-blue-900 dark:text-blue-100") do
              plain @record.title
            end
          end
        end
      end

      def render_badges
        # Show item count badge
        item_count = @record.descendant&.extract_active_ids_by_type("Item")&.count || 0
        if item_count > 0
          span(class: "shrink-0 rounded-full bg-blue-600 text-white px-2 py-0.5 text-xs") do
            plain "#{item_count} items"
          end
        end
      end

      def stimulus_data
        {
          controller: "list-link",
          list_link_id_value: @record.id,
          list_link_day_id_value: @day&.id,
          action: "click->list-link#openSheet",
          day_move_target: "item" # Still movable like items
        }
      end

      def render_actions_menu
        # No three-dot menu for list links (mobile-first, no hover)
      end
    end
  end
end
