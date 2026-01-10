# frozen_string_literal: true

module Views
  module Notes
    class DebugSheet < ::Views::Base
      def initialize(note:, parent_descendants: [])
        @note = note
        @parent_descendants = parent_descendants
      end

      def view_template
        # Render the debug modal structure directly
        div(data: { controller: "ruby-ui--sheet-content" }) do
          # Backdrop
          div(
            data_state: "open",
            data_action: "click->ruby-ui--sheet-content#close",
            class: "fixed pointer-events-auto inset-0 z-50 bg-black/50 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0"
          )

          # Modal content
          div(
            data_state: "open",
            class: "fixed pointer-events-auto z-50 bg-background p-6 shadow-lg transition ease-in-out data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:duration-300 data-[state=open]:duration-500 inset-x-0 bottom-0 border-t data-[state=closed]:slide-out-to-bottom data-[state=open]:slide-in-from-bottom max-h-[85vh] overflow-y-auto"
          ) do
            # Header
            div(class: "mb-4") do
              h2(class: "text-lg font-semibold") { "Note Details" }
            end

            # Content
            div(class: "space-y-4") do
              # Note JSON
              render_json_section("Note", @note.as_json)

              # Parent Descendants
              if @parent_descendants.any?
                @parent_descendants.each_with_index do |descendant, index|
                  render_json_section("Parent Descendant ##{index + 1} (#{descendant.descendable_type} ##{descendant.descendable_id})", descendant.as_json)
                end
              else
                div(class: "space-y-2") do
                  h3(class: "font-semibold text-sm") { "Parent Descendants" }
                  p(class: "text-sm text-muted-foreground") { "None" }
                end
              end
            end

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

      private

      def render_json_section(title, data)
        div(class: "space-y-2") do
          h3(class: "font-semibold text-sm") { title }
          pre(class: "bg-muted p-4 rounded-lg text-xs overflow-x-auto font-mono") do
            code { JSON.pretty_generate(data) }
          end
        end
      end
    end
  end
end
