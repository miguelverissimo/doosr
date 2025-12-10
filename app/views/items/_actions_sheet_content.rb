# frozen_string_literal: true

module Views
  module Items
    class ActionsSheetContent < Views::Base
      def initialize(item:, day: nil, item_index: nil, total_items: nil)
        @item = item
        @day = day
        @item_index = item_index
        @total_items = total_items
      end

      def view_template
        # Just render the content that goes inside the existing sheet
        div(id: "sheet_content_area") do
          SheetHeader do
            SheetTitle(class: "text-left") { @item.title }
            SheetDescription(class: "text-left text-xs text-muted-foreground") do
              "#{@item.item_type.titleize} • #{@item.state.titleize}"
            end
          end

          SheetMiddle(class: "py-4") do
            render Views::Items::ActionsSheetButtons.new(
              item: @item,
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
