# frozen_string_literal: true

module Views
  module Notes
    class ActionsSheetContent < ::Views::Base
      def initialize(note:, day: nil, list: nil, note_index: nil, total_notes: nil, is_public_list: false)
        @note = note
        @day = day
        @list = list
        @note_index = note_index
        @total_notes = total_notes
        @is_public_list = is_public_list
        @day_is_closed = @day&.closed? || false
      end

      def view_template
        div(id: "sheet_content_area") do
          SheetHeader do
            SheetTitle(class: "text-left") { "Note" }
            SheetDescription(class: "text-left text-xs text-muted-foreground") do
              div { "Created #{@note.created_at.strftime('%b %d, %Y')}" }
            end
          end

          SheetMiddle(class: "py-4 space-y-4") do
            # Note content - scrollable and preserves formatting
            div(class: "max-h-48 overflow-y-auto rounded-lg border bg-muted p-3") do
              p(class: "text-sm whitespace-pre-wrap") { @note.content }
            end

            # Action buttons
            render ::Views::Notes::ActionsSheetButtons.new(
              note: @note,
              day: @day,
              list: @list,
              note_index: @note_index,
              total_notes: @total_notes,
              is_public_list: @is_public_list
            )
          end
        end
      end
    end
  end
end
