# frozen_string_literal: true

module Views
  module DayListLinks
    class ActionsSheetContent < ::Views::Base
      def initialize(list:, day:, item_index: nil, total_items: nil)
        @list = list
        @day = day
        @item_index = item_index
        @total_items = total_items
      end

      def view_template
        div(id: "sheet_content_area") do
          SheetHeader do
            SheetTitle { @list.title }
            SheetDescription do
              div { "List • #{@list.list_type.titleize}" }
              item_count = @list.descendant&.extract_active_ids_by_type("Item")&.count || 0
              div { "#{item_count} items" }
            end
          end

          SheetMiddle(class: "py-4 space-y-4") do
            render ActionButtons.new(
              list: @list,
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
