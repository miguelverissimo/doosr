# frozen_string_literal: true

module Views
  module Ephemeries
    class List < ::Views::Base
      def initialize(ephemeries:, selected_date:)
        @ephemeries = ephemeries
        @selected_date = selected_date
      end

      def view_template
        # Sheet content structure
        div(
          id: "ephemeries_sheet",
          data: {
            controller: "ruby-ui--sheet-content"
          }
        ) do
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
            div(id: "ephemeries_drawer_content") do
              SheetHeader do
                SheetTitle(class: "text-left") { "Ephemeries" }
                SheetDescription(class: "text-left text-xs text-muted-foreground") do
                  formatted_date = @selected_date.strftime("%B %d, %Y")
                  "Astrological aspects affecting #{formatted_date}"
                end
              end

              SheetMiddle(class: "py-4") do
                # Scrollable content area
                div(class: "overflow-y-auto max-h-[70vh] space-y-4") do
                  if @ephemeries.any?
                    @ephemeries.each do |ephemery|
                      render Card.new(ephemery: ephemery, selected_date: @selected_date)
                    end
                  else
                    # Empty state
                    div(class: "text-center text-muted-foreground py-8") do
                      p { "No ephemeries affecting this date." }
                    end
                  end
                end
              end
            end

            # Close button
            button(
              type: "button",
              class: "absolute end-4 top-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:pointer-events-none data-[state=open]:bg-accent data-[state=open]:text-muted-foreground",
              data_action: "click->ruby-ui--sheet-content#close"
            ) do
              svg(
                width: "15",
                height: "15",
                viewbox: "0 0 15 15",
                fill: "none",
                xmlns: "http://www.w3.org/2000/svg",
                class: "h-4 w-4"
              ) do |s|
                s.path(
                  d: "M11.7816 4.03157C12.0062 3.80702 12.0062 3.44295 11.7816 3.2184C11.5571 2.99385 11.193 2.99385 10.9685 3.2184L7.50005 6.68682L4.03164 3.2184C3.80708 2.99385 3.44301 2.99385 3.21846 3.2184C2.99391 3.44295 2.99391 3.80702 3.21846 4.03157L6.68688 7.49999L3.21846 10.9684C2.99391 11.193 2.99391 11.557 3.21846 11.7816C3.44301 12.0061 3.80708 12.0061 4.03164 11.7816L7.50005 8.31316L10.9685 11.7816C11.193 12.0061 11.5571 12.0061 11.7816 11.7816C12.0062 11.557 12.0062 11.193 11.7816 10.9684L8.31322 7.49999L11.7816 4.03157Z",
                  fill: "currentColor",
                  fill_rule: "evenodd",
                  clip_rule: "evenodd"
                )
              end
              span(class: "sr-only") { "Close" }
            end
          end
        end
      end
    end
  end
end
