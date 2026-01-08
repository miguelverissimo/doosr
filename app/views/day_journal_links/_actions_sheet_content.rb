# frozen_string_literal: true

module Views
  module DayJournalLinks
    class ActionsSheetContent < ::Views::Base
      def initialize(journal:, day:, item_index: nil, total_items: nil)
        @journal = journal
        @day = day
        @item_index = item_index
        @total_items = total_items
      end

      def view_template
        div(id: "sheet_content_area") do
          SheetHeader do
            SheetTitle { "Journal" }
            SheetDescription do
              div { @journal.date_display }
              fragment_count = @journal.journal_fragments.count
              div { "#{fragment_count} #{fragment_count == 1 ? 'entry' : 'entries'}" }
            end
          end

          SheetMiddle(class: "py-4 space-y-4") do
            render ActionButtons.new(
              journal: @journal,
              day: @day,
              item_index: @item_index,
              total_items: @total_items
            )
          end
        end
      end
    end
  end
end
