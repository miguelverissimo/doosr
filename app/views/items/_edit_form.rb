# frozen_string_literal: true

module Views
  module Items
    class EditForm < ::Views::Base
      def initialize(item:, list: nil, day: nil)
        @item = item
        @list = list
        @day = day
      end

      def view_template
        div(id: "sheet_content_area", class: "flex flex-col gap-4 p-6") do
          # Header
          div(class: "flex items-center justify-between mb-4") do
            h2(class: "text-lg font-semibold") { "Edit Item" }
          end

          # Edit Form
          form(
            action: item_path(@item),
            method: "post",
            data: {
              controller: "form-loading",
              form_loading_message_value: "Saving changes...",
              turbo: "true"
            }
          ) do
            csrf_token_field
            input(type: "hidden", name: "_method", value: "patch")
            input(type: "hidden", name: "from_edit_form", value: "true")
            input(type: "hidden", name: "list_id", value: @list.id) if @list
            input(type: "hidden", name: "day_id", value: @day.id) if @day
            input(type: "hidden", name: "is_public_list", value: "true") if @list && !@day

            # Title Input
            div(class: "space-y-2") do
              label(for: "item_title", class: "text-sm font-medium") { "Title" }
              Input(
                type: "text",
                id: "item_title",
                name: "item[title]",
                value: @item.title,
                placeholder: "Item title...",
                required: true,
                autofocus: true
              )
            end

            # Notification Time Input
            div(class: "space-y-2") do
              label(for: "item_notification_time", class: "text-sm font-medium") { "Notification" }
              input(
                type: "datetime-local",
                id: "item_notification_time",
                name: "item[notification_time]",
                value: @item.notification_time&.strftime("%Y-%m-%dT%H:%M"),
                class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
              )
              p(class: "text-xs text-muted-foreground") { "Optional: Set a time to be notified about this item" }
            end

            # Action Buttons
            div(class: "flex items-center gap-2 mt-6") do
              Button(type: :submit, variant: :primary) do
                "Save"
              end

              # Build cancel URL to go back to action sheet
              cancel_params = {}
              cancel_params[:day_id] = @day.id if @day
              cancel_params[:list_id] = @list.id if @list
              cancel_params[:is_public_list] = "true" if @list && !@day
              cancel_params[:from_edit_form] = "true"
              cancel_url = actions_sheet_item_path(@item, cancel_params)

              button(
                type: "submit",
                formaction: cancel_url,
                formmethod: "get",
                data: { turbo_stream: true },
                class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2"
              ) do
                plain "Cancel"
              end
            end
          end
        end
      end
    end
  end
end
