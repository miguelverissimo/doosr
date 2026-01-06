# frozen_string_literal: true

module Views
  module Notes
    class NoteItem < ::Views::Base
      def initialize(note:, day: nil, list: nil, is_public_list: false)
        @note = note
        @day = day
        @list = list
        @is_public_list = is_public_list
      end

      def view_template
        controller_data = {
          controller: "note",
          note_id_value: @note.id,
          action: "click->note#openActions"
        }
        controller_data[:note_day_id_value] = @day.id if @day
        controller_data[:note_list_id_value] = @list.id if @list

        div(
          id: "note_#{@note.id}",
          class: "group flex items-start gap-2 rounded-lg border bg-yellow-50 dark:bg-yellow-900/20 p-2.5 hover:bg-yellow-100 dark:hover:bg-yellow-900/30 transition-colors cursor-pointer",
          data: controller_data
        ) do
          # Note icon
          div(class: "flex h-5 w-5 items-center justify-center shrink-0 mt-0.5") do
            render ::Components::Icon.new(name: :sticky_note, size: "16", class: "text-yellow-600 dark:text-yellow-400")
          end

          # Content preview - preserve user formatting with whitespace-pre-wrap, but limit to 2 lines
          div(class: "flex-1 min-w-0") do
            p(class: "text-sm whitespace-pre-wrap line-clamp-2") { @note.content }

            # Show parent context if viewing from notes index
            if !@day && !@list
              render_parent_context
            end
          end

          # Timestamp
          div(class: "shrink-0 text-xs text-muted-foreground") do
            @note.created_at.strftime("%b %d")
          end
        end
      end

      private

      def render_parent_context
        contexts = @note.parent_contexts
        return if contexts.empty?

        div(class: "mt-1 flex flex-wrap gap-1") do
          contexts.each do |context|
            span(class: "inline-flex items-center gap-1 rounded-full bg-muted px-2 py-0.5 text-xs text-muted-foreground") do
              case context[:type]
              when "Day"
                render ::Components::Icon.new(name: :calendar, size: "12", class: "shrink-0")
                plain context[:object].date.strftime("%b %d, %Y")
              when "Item"
                render ::Components::Icon.new(name: :check_square, size: "12", class: "shrink-0")
                plain context[:object].title.truncate(20)
              end
            end
          end
        end
      end
    end
  end
end
