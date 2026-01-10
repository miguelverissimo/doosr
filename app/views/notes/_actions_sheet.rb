# frozen_string_literal: true

module Views
  module Notes
    class ActionsSheet < ::Views::Base
      def initialize(note:, day: nil, list: nil, note_index: nil, total_notes: nil, is_public_list: false)
        @note = note
        @day = day
        @list = list
        @note_index = note_index
        @total_notes = total_notes
        @is_public_list = is_public_list
      end

      def view_template
        # Render the sheet content structure directly (bypassing template wrapper)
        div(
          id: "note_actions_sheet",
          data: {
            controller: "ruby-ui--sheet-content note-move",
            note_move_note_id_value: @note.id,
            note_move_day_id_value: @day&.id,
            note_move_list_id_value: @list&.id
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
            render ::Views::Notes::ActionsSheetContent.new(
              note: @note,
              day: @day,
              list: @list,
              note_index: @note_index,
              total_notes: @total_notes,
              is_public_list: @is_public_list
            )

            # Close button
            Button(
              type: :button,
              variant: :ghost,
              icon: true,
              class: "absolute end-4 top-4",
              data: { action: "click->ruby-ui--sheet-content#close" }
            ) do
              render ::Components::Icon::X.new(size: "16")
            end
          end
        end
      end
    end
  end
end
