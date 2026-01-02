# frozen_string_literal: true

module Views
  module Checklists
    class Item < ::Views::Base
      def initialize(checklist:, item:, item_index:)
        @checklist = checklist
        @item = item
        @item_index = item_index
      end

      def view_template
        div(class: item_classes) do
          render_checkbox
          render_content
        end
      end

      private

      def item_classes
        base_classes = "flex items-center gap-3 rounded-lg border bg-card p-3 transition-colors"

        if completed?
          "#{base_classes} opacity-60"
        elsif disabled?
          "#{base_classes} opacity-40"
        else
          "#{base_classes} hover:bg-accent/50"
        end
      end

      def render_checkbox
        form(
          action: view_context.complete_item_checklist_path(@checklist),
          method: "post",
          data: {
            controller: "form-loading checklists--item",
            form_loading_message_value: completed? ? "Marking as incomplete..." : "Marking as complete...",
            turbo_stream: true
          },
          class: "shrink-0"
        ) do
          csrf_token_field
          input(type: "hidden", name: "_method", value: "patch")
          input(type: "hidden", name: "item_index", value: @item_index)

          # Custom styled checkbox wrapper
          label(class: "relative inline-flex items-center cursor-pointer shrink-0") do
            input(
              type: "checkbox",
              checked: completed?,
              disabled: disabled?,
              class: "sr-only peer",
              data: { action: "change->checklists--item#submitForm" }
            )

            # Custom checkbox visual
            div(class: "h-5 w-5 rounded-sm border border-primary bg-background peer-checked:bg-primary peer-checked:border-primary peer-disabled:opacity-50 peer-disabled:cursor-not-allowed peer-focus-visible:ring-2 peer-focus-visible:ring-ring peer-focus-visible:ring-offset-2 flex items-center justify-center transition-colors") do
              # Checkmark (conditionally rendered when checked)
              if completed?
                render ::Components::Icon.new(name: :check, size: "14", class: "text-primary-foreground", stroke_width: "3")
              end
            end
          end
        end
      end

      def render_content
        div(class: "flex-1 min-w-0") do
          title_classes = [ "text-sm" ]
          title_classes << "line-through text-muted-foreground" if completed?
          p(class: title_classes.join(" ")) { @item["title"] }
        end
      end

      def completed?
        @item["completed_at"].present?
      end

      def disabled?
        return false unless @checklist.sequential?
        return false if completed?

        # For sequential: disabled if any previous item is not completed
        (0...@item_index).any? do |i|
          prev_item = @checklist.items[i]
          prev_item["completed_at"].blank?
        end
      end
    end
  end
end
