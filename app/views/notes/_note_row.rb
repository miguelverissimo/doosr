# frozen_string_literal: true

module Views
  module Notes
    class NoteRow < ::Views::Base
      def initialize(note:, search_query: nil, page: 1)
        @note = note
        @search_query = search_query
        @page = page
      end

      def view_template
        div(
          id: "note_row_#{@note.id}",
          class: "group flex items-start gap-3 rounded-lg border bg-card p-3 hover:bg-accent/50 transition-colors"
        ) do
          # Note icon
          div(class: "flex h-5 w-5 items-center justify-center shrink-0 mt-0.5") do
            render ::Components::Icon.new(name: :sticky_note, size: "16", class: "text-yellow-600 dark:text-yellow-400")
          end

          # Content
          div(class: "flex-1 min-w-0") do
            p(class: "text-sm whitespace-pre-wrap break-words mb-2") { @note.content }

            # Parent contexts
            contexts = @note.parent_contexts
            if contexts.any?
              div(class: "flex flex-wrap gap-1 mb-2") do
                contexts.each do |context|
                  span(class: "inline-flex items-center gap-1 rounded-full bg-muted px-2 py-0.5 text-xs text-muted-foreground") do
                    case context[:type]
                    when "Day"
                      render ::Components::Icon.new(name: :calendar, size: "12", class: "shrink-0")
                      plain context[:object].date.strftime("%b %d, %Y")
                    when "Item"
                      render ::Components::Icon.new(name: :check_square, size: "12", class: "shrink-0")
                      plain context[:object].title.truncate(30)
                    end
                  end
                end
              end
            end

            # Timestamp
            div(class: "text-xs text-muted-foreground") do
              "Created #{@note.created_at.strftime('%b %d, %Y at %l:%M %p')}"
            end
          end

          # Actions
          div(class: "flex gap-1 shrink-0") do
            # Edit button
            Button(
              href: view_context.edit_note_path(@note),
              variant: :ghost,
              icon: true,
              size: :sm,
              data: { turbo_stream: true }
            ) do
              render ::Components::Icon.new(name: :edit, size: "16")
            end

            # Delete button
            form(
              action: view_context.note_path(@note),
              method: "post",
              data: {
                turbo_method: :delete,
                turbo_confirm: "Are you sure you want to delete this note?"
              },
              class: "inline-block"
            ) do
              csrf_token_field
              Button(
                variant: :ghost,
                icon: true,
                size: :sm,
                type: :submit,
                class: "hover:bg-destructive/10 hover:text-destructive"
              ) do
                render ::Components::Icon.new(name: :delete, size: "16")
              end
            end
          end
        end
      end
    end
  end
end
