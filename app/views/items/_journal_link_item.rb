# frozen_string_literal: true

module Views
  module Items
    class JournalLinkItem < BaseItem
      def item_classes
        "group flex items-center gap-2 rounded-lg border border-teal-500/30 bg-teal-50 dark:bg-teal-950/20 p-2.5 hover:bg-teal-100 dark:hover:bg-teal-950/30 transition-colors cursor-pointer"
      end

      def render_icon
        # Journal icon - navigates to the journal
        a(
          href: journal_path(@record),
          data: {
            turbo: false,
            action: "click->journal-link#navigateToJournal"
          },
          class: "shrink-0"
        ) do
          render ::Components::Icon.new(name: :journal, size: "16", class: "text-teal-600 dark:text-teal-400")
        end
      end

      def render_content
        # Wrapper takes flex space, but title link is only as wide as text
        div(class: "flex-1 min-w-0") do
          a(
            href: journal_path(@record),
            data: {
              turbo: false,
              action: "click->journal-link#navigateToJournal"
            },
            class: "inline-block"
          ) do
            span(class: "text-sm font-medium text-teal-900 dark:text-teal-100") do
              plain "Journal"
            end
          end
        end
      end

      def render_badges
        # Show fragment count badge
        fragment_count = @record.journal_fragments.count
        if fragment_count > 0
          span(class: "shrink-0 rounded-full bg-teal-600 text-white px-2 py-0.5 text-xs") do
            plain "#{fragment_count} #{fragment_count == 1 ? 'entry' : 'entries'}"
          end
        end
      end

      def stimulus_data
        {
          controller: "journal-link",
          journal_link_id_value: @record.id,
          journal_link_day_id_value: @day&.id,
          action: "click->journal-link#openSheet",
          day_move_target: "item" # Still movable like items
        }
      end

      def render_actions_menu
        # No three-dot menu for journal links (mobile-first, no hover)
      end
    end
  end
end
