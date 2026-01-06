# frozen_string_literal: true

module Views
  module Notes
    class ActionsSheetButtons < ::Views::Base
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
        div(id: "action_sheet_buttons_#{@note.id}", class: "flex items-center justify-between gap-2") do
          # Left side - primary actions
          div(class: "flex items-center gap-2") do
            # Edit
            if @day_is_closed
              Button(
                variant: :outline,
                icon: true,
                size: :md,
                disabled: true,
                class: "opacity-50"
              ) do
                render ::Components::Icon.new(name: :edit, size: "20")
              end
            else
              Button(
                href: view_context.edit_note_path(@note, day_id: @day&.id, list_id: @list&.id),
                variant: :outline,
                icon: true,
                size: :md,
                data: { turbo_stream: true }
              ) do
                render ::Components::Icon.new(name: :edit, size: "20")
              end
            end

            # Delete
            if @day_is_closed
              Button(
                variant: :outline,
                icon: true,
                size: :md,
                disabled: true,
                class: "opacity-50"
              ) do
                render ::Components::Icon.new(name: :trash, size: "20")
              end
            else
              Button(
                variant: :outline,
                icon: true,
                size: :md,
                type: :button,
                class: "border-destructive text-destructive hover:bg-destructive hover:text-destructive-foreground",
                data: {
                  controller: "note",
                  note_id_value: @note.id,
                  note_day_id_value: @day&.id,
                  note_list_id_value: @list&.id,
                  action: "click->note#confirmDelete"
                }
              ) do
                render ::Components::Icon.new(name: :trash, size: "20")
              end
            end
          end

          # Right side - utility actions
          div(class: "flex items-center gap-2") do
            # Reparent/Move
            if @day_is_closed
              Button(
                variant: :outline,
                icon: true,
                size: :md,
                disabled: true,
                class: "opacity-50"
              ) do
                render ::Components::Icon.new(name: :move, size: "20")
              end
            else
              Button(
                variant: :outline,
                icon: true,
                size: :md,
                type: :button,
                data: {
                  controller: "note-move",
                  note_move_note_id_value: @note.id,
                  note_move_day_id_value: @day&.id,
                  note_move_list_id_value: @list&.id,
                  action: "click->note-move#startMoving"
                }
              ) do
                render ::Components::Icon.new(name: :move, size: "20")
              end
            end

            # Move Up
            can_move_up = @note_index && @note_index > 0 && !@day_is_closed
            render_icon_button(
              icon: :arrow_up,
              action: view_context.move_note_path(@note),
              method: "patch",
              params: { "direction" => "up", "day_id" => @day&.id, "list_id" => @list&.id },
              disabled: !can_move_up,
              loading_message: "Moving note up..."
            )

            # Move Down
            can_move_down = @note_index && @total_notes && @note_index < (@total_notes - 1) && !@day_is_closed
            render_icon_button(
              icon: :arrow_down,
              action: view_context.move_note_path(@note),
              method: "patch",
              params: { "direction" => "down", "day_id" => @day&.id, "list_id" => @list&.id },
              disabled: !can_move_down,
              loading_message: "Moving note down..."
            )

            # Debug
            Button(
              variant: :outline,
              icon: true,
              size: :md,
              type: :button,
              data: {
                controller: "note",
                note_id_value: @note.id,
                action: "click->note#openDebug"
              }
            ) do
              render ::Components::Icon.new(name: :bug, size: "20")
            end
          end
        end
      end

      private

      def render_icon_button(icon:, action: nil, method: "post", params: {}, disabled: false, variant: :default, loading_message: "Processing...")
        if disabled
          Button(
            variant: :outline,
            icon: true,
            size: :md,
            disabled: true,
            class: "opacity-50"
          ) do
            render ::Components::Icon.new(name: icon, size: "20")
          end
        else
          form(
            action: action,
            method: "post",
            data: {
              controller: "form-loading",
              form_loading_message_value: loading_message,
              turbo: "true"
            },
            class: "inline-block"
          ) do
            csrf_token_field
            input(type: "hidden", name: "_method", value: method) if method != "post"

            params.each do |key, value|
              input(type: "hidden", name: key, value: value)
            end

            Button(
              variant: variant == :destructive ? :destructive : :outline,
              icon: true,
              size: :md,
              type: :submit
            ) do
              render ::Components::Icon.new(name: icon, size: "20")
            end
          end
        end
      end
    end
  end
end
