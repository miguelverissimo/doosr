# frozen_string_literal: true

module Views
  module Notes
    class FormDialog < ::Views::Base
      def initialize(note:, day: nil, item: nil)
        @note = note
        @day = day
        @item = item
      end

      def view_template
        div(id: "note_dialog") do
          render RubyUI::Dialog.new(open: true) do
            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { @note.new_record? ? "Add Note" : "Edit Note" }
                render RubyUI::DialogDescription.new do
                  if @day
                    "Add a note to #{@day.date.strftime('%b %d, %Y')}"
                  elsif @item
                    "Add a note to '#{@item.title}'"
                  else
                    @note.new_record? ? "Create a new note" : "Edit this note"
                  end
                end
              end

              render RubyUI::DialogMiddle.new do
                render_form
              end
            end
          end
        end
      end

      private

      def render_form
        # Determine form action based on context
        form_action = if @day
          view_context.day_day_notes_path(@day)
        elsif @item
          view_context.item_item_notes_path(@item)
        elsif @note.new_record?
          view_context.notes_path
        else
          view_context.note_path(@note)
        end

        form_method = @note.new_record? ? "post" : "patch"

        form(
          action: form_action,
          method: "post",
          data: {
            controller: "modal-form",
            modal_form_loading_message_value: @note.new_record? ? "Creating note..." : "Updating note...",
            modal_form_success_message_value: @note.new_record? ? "Note created successfully" : "Note updated successfully",
            turbo: true
          },
          class: "space-y-4"
        ) do
          csrf_token_field
          input(type: "hidden", name: "_method", value: form_method) unless @note.new_record?

          # Error container
          div(id: "note_form_errors", class: "text-sm text-destructive")

          # Content textarea
          div(class: "space-y-2") do
            label(for: "note_content", class: "text-sm font-medium") { "Content" }
            textarea(
              id: "note_content",
              name: "note[content]",
              rows: "6",
              required: true,
              autofocus: true,
              class: "flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 resize-none"
            ) { @note.content }
          end

          # Actions
          div(class: "flex gap-2 justify-end mt-6") do
            Button(variant: :outline, type: "button", data: { action: "click->ruby-ui--dialog#dismiss" }) { "Cancel" }
            Button(variant: :primary, type: "submit") do
              @note.new_record? ? "Create Note" : "Update Note"
            end
          end
        end
      end
    end
  end
end
