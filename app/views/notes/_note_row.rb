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
          class: "group flex items-start gap-3 rounded-lg border bg-card px-4 py-2 hover:shadow-sm transition-shadow"
        ) do
          # Note icon
          render ::Components::Icon::StickyNote.new(size: "16", class: "text-yellow-600 dark:text-yellow-400 mt-0.5 flex-shrink-0")

          # Content
          div(class: "flex-1 min-w-0") do
            div(class: "prose prose-sm dark:prose-invert max-w-none") do
              raw @note.rendered_markdown
            end

            # Parent contexts and timestamp on same line
            div(class: "flex flex-wrap items-center gap-x-3 gap-y-1 mt-1") do
              contexts = @note.parent_contexts
              contexts.each do |context|
                case context[:type]
                when "Day"
                  a(
                    href: view_context.day_path(date: context[:object].date),
                    class: "inline-flex items-center gap-1 rounded-full bg-muted px-2 py-0.5 text-xs text-muted-foreground hover:bg-accent transition-colors"
                  ) do
                    render ::Components::Icon::Calendar.new(size: "12", class: "shrink-0")
                    plain context[:object].date.strftime("%b %d, %Y")
                  end
                when "Item"
                  day = find_day_for_item(context[:object])
                  if day
                    a(
                      href: view_context.day_path(date: day.date),
                      class: "inline-flex items-center gap-1 rounded-full bg-muted px-2 py-0.5 text-xs text-muted-foreground hover:bg-accent transition-colors"
                    ) do
                      render ::Components::Icon::CheckSquare.new(size: "12", class: "shrink-0")
                      plain context[:object].title.truncate(30)
                    end
                  else
                    span(class: "inline-flex items-center gap-1 rounded-full bg-muted px-2 py-0.5 text-xs text-muted-foreground") do
                      render ::Components::Icon::CheckSquare.new(size: "12", class: "shrink-0")
                      plain context[:object].title.truncate(30)
                    end
                  end
                end
              end

              span(class: "text-xs text-muted-foreground") do
                plain "Created #{@note.created_at.strftime('%b %d, %Y at %l:%M %p')}"
              end
            end
          end

          # Actions
          div(class: "flex gap-2 flex-shrink-0") do
            # Edit button
            Button(
              variant: :secondary,
              size: :sm,
              icon: true,
              data: {
                controller: "note-edit",
                note_edit_url_value: view_context.edit_note_path(@note),
                action: "click->note-edit#openDialog"
              }
            ) do
              render ::Components::Icon::Edit.new(size: "12")
            end

            # Delete button
            render RubyUI::AlertDialog.new do
              render RubyUI::AlertDialogTrigger.new do
                Button(variant: :destructive, size: :sm, icon: true) do
                  render ::Components::Icon::Delete.new(size: "12")
                end
              end

              render RubyUI::AlertDialogContent.new do
                render RubyUI::AlertDialogHeader.new do
                  render RubyUI::AlertDialogTitle.new { "Delete this note?" }
                  render RubyUI::AlertDialogDescription.new { "This action cannot be undone." }
                end

                render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                  render RubyUI::AlertDialogCancel.new { "Cancel" }

                  form(
                    action: view_context.note_path(@note),
                    method: "post",
                    data: { turbo_stream: true, action: "submit@document->ruby-ui--alert-dialog#dismiss" },
                    class: "inline"
                  ) do
                    csrf_token_field
                    input(type: "hidden", name: "_method", value: "delete")
                    render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                  end
                end
              end
            end
          end
        end
      end

      private

      def find_day_for_item(item)
        # Trace up the descendant hierarchy to find the Day
        current = item
        visited = Set.new

        while current
          # Prevent infinite loops
          return nil if visited.include?(current.id)
          visited.add(current.id)

          # Find the descendant containing this item
          descendant = ::Descendant.containing_item(current.id)
          return nil unless descendant

          # Check what the descendant belongs to
          case descendant.descendable_type
          when "Day"
            return descendant.descendable
          when "Item"
            # Continue tracing up
            current = descendant.descendable
          else
            # List or other - no day to link to
            return nil
          end
        end

        nil
      end
    end
  end
end
