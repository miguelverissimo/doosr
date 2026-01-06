# frozen_string_literal: true

module Views
  module Notes
    class EditForm < ::Views::Base
      def initialize(note:, day: nil, list: nil)
        @note = note
        @day = day
        @list = list
      end

      def view_template
        div(id: "sheet_content_area", class: "flex flex-col gap-4 p-6") do
          # Header
          div(class: "flex items-center justify-between mb-4") do
            h2(class: "text-lg font-semibold") { "Edit Note" }
          end

          # Edit Form
          form(
            action: view_context.note_path(@note),
            method: "post",
            data: {
              controller: "modal-form",
              modal_form_loading_message_value: "Saving changes...",
              modal_form_success_message_value: "Note updated successfully",
              turbo: true
            }
          ) do
            csrf_token_field
            input(type: "hidden", name: "_method", value: "patch")
            input(type: "hidden", name: "day_id", value: @day.id) if @day
            input(type: "hidden", name: "list_id", value: @list.id) if @list
            input(type: "hidden", name: "from_edit_form", value: "true")

            # Content textarea
            div(class: "space-y-2") do
              label(for: "note_content", class: "text-sm font-medium") { "Content" }
              textarea(
                id: "note_content",
                name: "note[content]",
                rows: "10",
                required: true,
                autofocus: true,
                class: "flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 resize-none"
              ) { @note.content }
            end

            # Action Buttons
            div(class: "flex items-center gap-2 mt-6") do
              Button(type: :submit, variant: :primary) { "Save" }

              # Cancel button - go back to actions sheet
              cancel_params = {}
              cancel_params[:day_id] = @day.id if @day
              cancel_params[:list_id] = @list.id if @list
              cancel_url = view_context.actions_sheet_note_path(@note, cancel_params)

              Button(
                type: :submit,
                variant: :outline,
                formaction: cancel_url,
                formmethod: "get",
                data: { turbo_stream: true }
              ) { "Cancel" }
            end
          end
        end
      end
    end
  end
end
