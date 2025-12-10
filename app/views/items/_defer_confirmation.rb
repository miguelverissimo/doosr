# frozen_string_literal: true

module Views
  module Items
    class DeferConfirmation < Views::Base
      def initialize(item:, target_date:, target_date_param:, day: nil)
        @item = item
        @target_date = target_date
        @target_date_param = target_date_param
        @day = day
      end

      def view_template
        # Just render the content that goes inside the existing sheet
        div(id: "sheet_content_area") do
          SheetHeader do
            SheetTitle(class: "text-left") { "Defer item with nested items?" }
            SheetDescription(class: "text-left text-xs text-muted-foreground") do
              "This item has nested items. All nested items will also be deferred. Continue?"
            end
          end

          SheetMiddle(class: "py-4") do
            # Show count of items that will be deferred
            p(class: "text-sm text-muted-foreground") do
              "#{@item.nested_item_count} nested item#{@item.nested_item_count > 1 ? 's' : ''} will be deferred to #{@target_date.strftime('%B %-d, %Y')}"
            end
          end

          SheetFooter(class: "flex gap-2") do
            # Cancel button - go back to defer options
            a(
              href: defer_options_item_path(@item, day_id: @day&.id),
              class: "flex-1 h-12 px-4 py-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground rounded-md font-medium transition-colors flex items-center justify-center",
              data: {
                turbo_stream: true,
                turbo_method: :get
              }
            ) do
              "Cancel"
            end

            # Confirm button
            form(
              action: defer_item_path(@item),
              method: "post",
              data: { turbo: "true" },
              class: "flex-1"
            ) do
              csrf_token_field
              input(type: "hidden", name: "_method", value: "patch")
              input(type: "hidden", name: "target_date", value: @target_date_param)
              input(type: "hidden", name: "day_id", value: @day&.id) if @day
              input(type: "hidden", name: "confirmed", value: "true")

              button(
                type: "submit",
                class: "w-full h-12 px-4 py-2 bg-primary text-primary-foreground hover:bg-primary/90 rounded-md font-medium transition-colors"
              ) do
                "Confirm"
              end
            end
          end
        end
      end
    end
  end
end
