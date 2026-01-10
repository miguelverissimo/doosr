# frozen_string_literal: true

module Views
  module Items
    class ChecklistLinkItem < BaseItem
      def item_classes
        "group flex items-center gap-2 rounded-lg border border-purple-500/30 bg-purple-50 dark:bg-purple-950/20 p-2.5 hover:bg-purple-100 dark:hover:bg-purple-950/30 transition-colors cursor-pointer"
      end

      def render_icon
        # Checklist icon - navigates to the checklist
        a(
          href: checklist_path(@record),
          data: {
            turbo: false,
            action: "click->checklist-link#navigateToChecklist"
          },
          class: "shrink-0"
        ) do
          render ::Components::Icon::Checklist.new(size: "16", class: "text-purple-600 dark:text-purple-400")
        end
      end

      def render_content
        # Wrapper takes flex space, but title link is only as wide as text
        div(class: "flex-1 min-w-0") do
          a(
            href: checklist_path(@record),
            data: {
              turbo: false,
              action: "click->checklist-link#navigateToChecklist"
            },
            class: "inline-block"
          ) do
            span(class: "text-sm font-medium text-purple-900 dark:text-purple-100") do
              plain @record.name
            end
          end
        end
      end

      def render_badges
        # Show progress badge
        completed_count = @record.items.count { |item| item["completed_at"].present? }
        total_count = @record.items.length

        if total_count > 0
          # Different styling based on completion
          if completed_count == total_count
            badge_classes = "shrink-0 rounded-full bg-green-600 text-white px-2 py-0.5 text-xs"
          else
            badge_classes = "shrink-0 rounded-full bg-purple-600 text-white px-2 py-0.5 text-xs"
          end

          span(class: badge_classes) do
            plain "#{completed_count}/#{total_count}"
          end
        end
      end

      def stimulus_data
        {
          controller: "checklist-link",
          checklist_link_id_value: @record.id,
          checklist_link_day_id_value: @day&.id,
          action: "click->checklist-link#openSheet",
          day_move_target: "item" # Still movable like items
        }
      end

      def render_actions_menu
        # No three-dot menu for checklist links (mobile-first, no hover)
      end
    end
  end
end
