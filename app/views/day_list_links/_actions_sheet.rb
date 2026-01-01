# frozen_string_literal: true

module Views
  module DayListLinks
    class ActionsSheet < ::Views::Base
      def initialize(list:, day:, item_index: nil, total_items: nil)
        @list = list
        @day = day
        @item_index = item_index
        @total_items = total_items
      end

      def view_template
        div(id: "item_actions_sheet", data: { controller: "ruby-ui--sheet-content" }) do
          # Backdrop
          div(
            data_state: "open",
            data_action: "click->ruby-ui--sheet-content#close",
            class: "fixed pointer-events-auto inset-0 z-50 bg-black/50 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0"
          )

          # Sheet content
          div(
            data_state: "open",
            class: "fixed pointer-events-auto z-50 gap-4 bg-background p-6 shadow-lg transition ease-in-out data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:duration-300 data-[state=open]:duration-500 inset-x-0 bottom-0 border-t data-[state=closed]:slide-out-to-bottom data-[state=open]:slide-in-from-bottom max-h-[85vh]"
          ) do
            render ActionsSheetContent.new(
              list: @list,
              day: @day,
              item_index: @item_index,
              total_items: @total_items
            )

            # Close button
            button(
              type: "button",
              class: "absolute end-4 top-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:pointer-events-none data-[state=open]:bg-accent data-[state=open]:text-muted-foreground",
              data_action: "click->ruby-ui--sheet-content#close"
            ) do
              render ::Components::Icon.new(name: :x, size: "16", class: "h-4 w-4")
              span(class: "sr-only") { "Close" }
            end
          end
        end
      end
    end
  end
end
