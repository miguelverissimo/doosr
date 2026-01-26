# frozen_string_literal: true

module Views
  module Items
    class DropSectionConfirmation < ::Views::Base
      def initialize(section:, day: nil, active_children_count: 0)
        @section = section
        @day = day
        @active_children_count = active_children_count
      end

      def view_template
        div(id: "sheet_content_area") do
          SheetHeader do
            SheetTitle(class: "text-left") { "Drop section?" }
            SheetDescription(class: "text-left text-xs text-muted-foreground") do
              if @active_children_count > 0
                "This section has active children. Dropping the section will also drop all children tasks."
              else
                "This will drop the section."
              end
            end
          end

          if @active_children_count > 0
            SheetMiddle(class: "py-4") do
              p(class: "text-sm text-muted-foreground") do
                "#{@active_children_count} active item#{@active_children_count > 1 ? 's' : ''} will also be dropped"
              end
            end
          end

          SheetFooter(class: "flex gap-2") do
            # Cancel button - go back to actions sheet
            a(
              href: actions_sheet_item_path(@section, day_id: @day&.id, from_edit_form: true),
              class: "flex-1 h-12 px-4 py-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground rounded-md font-medium transition-colors flex items-center justify-center",
              data: {
                turbo_stream: true
              }
            ) do
              "Cancel"
            end

            # Confirm button
            form(
              action: drop_section_item_path(@section),
              method: "post",
              data: {
                controller: "form-loading",
                form_loading_message_value: "Dropping section...",
                turbo: "true"
              },
              class: "flex-1"
            ) do
              csrf_token_field
              input(type: "hidden", name: "_method", value: "patch")
              input(type: "hidden", name: "day_id", value: @day&.id) if @day
              input(type: "hidden", name: "confirmed", value: "true")

              button(
                type: "submit",
                class: "w-full h-12 px-4 py-2 bg-destructive text-destructive-foreground hover:bg-destructive/90 rounded-md font-medium transition-colors"
              ) do
                "Drop"
              end
            end
          end
        end
      end
    end
  end
end
