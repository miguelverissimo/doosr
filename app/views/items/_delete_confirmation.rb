# frozen_string_literal: true

module Views
  module Items
    class DeleteConfirmation < Views::Base
      def initialize(item:, day: nil, list: nil)
        @item = item
        @day = day
        @list = list
      end

      def view_template
        # Just render the content that goes inside the existing sheet
        div(id: "sheet_content_area") do
          SheetHeader do
            SheetTitle(class: "text-left") { "Delete item with nested items?" }
            SheetDescription(class: "text-left text-xs text-muted-foreground") do
              "This item has nested items. All nested items will also be deleted. This cannot be undone!"
            end
          end

          SheetMiddle(class: "py-4") do
            # Show count of items that will be deleted
            p(class: "text-sm text-muted-foreground") do
              "#{@item.nested_item_count} nested item#{@item.nested_item_count > 1 ? 's' : ''} will be permanently deleted"
            end
          end

          SheetFooter(class: "flex gap-2") do
            # Cancel button - go back to actions sheet
            a(
              href: actions_sheet_item_path(@item, day_id: @day&.id, list_id: @list&.id, from_edit_form: true),
              class: "flex-1 h-12 px-4 py-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground rounded-md font-medium transition-colors flex items-center justify-center",
              data: {
                turbo_stream: true
              }
            ) do
              "Cancel"
            end

            # Confirm button
            form(
              action: item_path(@item),
              method: "post",
              data: {
                controller: "form-loading",
                form_loading_message_value: "Deleting item...",
                turbo: "true"
              },
              class: "flex-1"
            ) do
              csrf_token_field
              input(type: "hidden", name: "_method", value: "delete")
              input(type: "hidden", name: "day_id", value: @day&.id) if @day
              input(type: "hidden", name: "list_id", value: @list&.id) if @list
              input(type: "hidden", name: "confirmed", value: "true")

              button(
                type: "submit",
                class: "w-full h-12 px-4 py-2 bg-destructive text-destructive-foreground hover:bg-destructive/90 rounded-md font-medium transition-colors"
              ) do
                "Delete All"
              end
            end
          end
        end
      end
    end
  end
end
