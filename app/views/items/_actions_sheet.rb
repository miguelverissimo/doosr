# frozen_string_literal: true

module Views
  module Items
    class ActionsSheet < ::Views::Base
      def initialize(item:, day: nil, list: nil, item_index: nil, total_items: nil, is_public_list: false, is_editable: false)
        @item = item
        @day = day
        @list = list
        @item_index = item_index
        @total_items = total_items
        @is_public_list = is_public_list
        @is_editable = is_editable
      end

      def view_template
        # Render the sheet content structure directly (bypassing template wrapper)
        div(
          id: "actions_sheet",
          data: {
            controller: "ruby-ui--sheet-content item-move",
            item_move_item_id_value: @item.id,
            item_move_day_id_value: @day&.id,
            item_move_list_id_value: @list&.id
          }
        ) do
          # Backdrop
          div(
            data_state: "open",
            data_action: "click->ruby-ui--sheet-content#close",
            class: "fixed pointer-events-auto inset-0 z-50 bg-black/50 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0"
          )

          # Sheet content - responsive padding and height
          div(
            data_state: "open",
            class: "fixed pointer-events-auto z-50 gap-4 bg-background shadow-lg transition ease-in-out data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:duration-300 data-[state=open]:duration-500 inset-x-0 bottom-0 border-t data-[state=closed]:slide-out-to-bottom data-[state=open]:slide-in-from-bottom max-h-[90vh] md:max-h-[85vh] p-4 md:p-6 overflow-y-auto rounded-t-xl md:rounded-t-none"
          ) do
            # Drag handle for mobile
            div(class: "flex justify-center mb-3 md:hidden") do
              div(class: "w-12 h-1.5 bg-muted-foreground/30 rounded-full")
            end

            render ::Views::Items::ActionsSheetContentWrapper.new(
              item: @item,
              day: @day,
              list: @list,
              item_index: @item_index,
              total_items: @total_items,
              is_public_list: @is_public_list,
              is_editable: @is_editable
            )

            # Close button - larger touch target on mobile
            button(
              type: "button",
              class: "absolute end-3 top-3 md:end-4 md:top-4 p-2 md:p-0 rounded-full md:rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:pointer-events-none data-[state=open]:bg-accent data-[state=open]:text-muted-foreground",
              data_action: "click->ruby-ui--sheet-content#close"
            ) do
              render ::Components::Icon::X.new(size: "20", class: "md:h-4 md:w-4")
              span(class: "sr-only") { "Close" }
            end
          end
        end
      end
    end
  end
end
