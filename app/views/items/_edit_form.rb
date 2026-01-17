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
          render RubyUI::Form.new(
            id: "edit_item_form",
            action: item_path(@item),
            method: "post",
            data: {
              controller: "form-loading",
              form_loading_message_value: "Saving changes...",
              turbo: "true"
            }
          ) do
            # Hidden fields - MUST use RubyUI::Input
            render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch")
            render RubyUI::Input.new(type: :hidden, name: "from_edit_form", value: "true")
            render RubyUI::Input.new(type: :hidden, name: "list_id", value: @list.id) if @list
            render RubyUI::Input.new(type: :hidden, name: "day_id", value: @day.id) if @day
            render RubyUI::Input.new(type: :hidden, name: "is_public_list", value: "true") if @list && !@day

            # Title Input
            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new(for: "item_title") { "Title" }
              render RubyUI::Input.new(
                type: :text,
                id: "item_title",
                name: "item[title]",
                value: @item.title,
                placeholder: "Item title...",
                required: true,
                autofocus: true
              )
              render RubyUI::FormFieldError.new
            end

            # Unfurled URL fields (only show if item has been unfurled)
            if @item.has_unfurled_url?
              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new(for: "item_unfurled_url") { "Link URL" }
                render RubyUI::Input.new(
                  type: :url,
                  id: "item_unfurled_url",
                  name: "item[extra_data][unfurled_url]",
                  value: @item.unfurled_url,
                  placeholder: "https://..."
                )
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new(for: "item_unfurled_description") { "Description" }
                render RubyUI::Textarea.new(
                  id: "item_unfurled_description",
                  name: "item[extra_data][unfurled_description]",
                  rows: 3
                ) do
                  @item.unfurled_description
                end
                render RubyUI::FormFieldError.new
              end

              # Preview image info and remove option
              if @item.preview_image.attached?
                render RubyUI::FormField.new do
                  render RubyUI::FormFieldLabel.new { "Preview Image" }
                  div(class: "flex items-center gap-3") do
                    img(
                      src: view_context.url_for(@item.preview_image),
                      class: "w-16 h-16 rounded object-cover"
                    )
                    div(class: "flex-1") do
                      p(class: "text-sm text-muted-foreground") { @item.preview_image.filename.to_s }
                      p(class: "text-xs text-muted-foreground") do
                        "#{(@item.preview_image.byte_size / 1024.0).round(1)} KB"
                      end
                    end
                    label(class: "flex items-center gap-2 text-sm") do
                      render RubyUI::Input.new(
                        type: :checkbox,
                        name: "item[remove_preview_image]",
                        value: "1"
                      )
                      plain "Remove image"
                    end
                  end
                end
              end
            end

            # Notification Time Input
            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new(for: "item_notification_time") { "Notification" }
              render RubyUI::Input.new(
                type: "datetime-local",
                id: "item_notification_time",
                name: "item[notification_time]",
                value: @item.notification_time&.strftime("%Y-%m-%dT%H:%M"),
                class: "date-input-icon-light-dark"
              )
              p(class: "text-xs text-muted-foreground") { "Optional: Set a time to be notified about this item" }
              render RubyUI::FormFieldError.new
            end

          end

          # Action Buttons - outside main form
          div(class: "flex justify-center items-center gap-3 mt-6") do
            # Save button associated with main form via form attribute
            Button(type: :submit, variant: :primary, form: "edit_item_form") { "Save" }

            cancel_params = { from_edit_form: "true" }
            cancel_params[:day_id] = @day.id if @day
            cancel_params[:list_id] = @list.id if @list
            cancel_params[:is_public_list] = "true" if @list && !@day

            Button(
              type: :button,
              variant: :outline,
              data: {
                controller: "drawer-back",
                drawer_back_url_value: actions_sheet_item_path(@item, cancel_params),
                action: "click->drawer-back#goBack"
              }
            ) { "Cancel" }
          end
        end
      end
    end
  end
end
