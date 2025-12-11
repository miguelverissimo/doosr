# frozen_string_literal: true

module Views
  module Items
    class DrawerChildItem < Views::Base
      def initialize(item:, parent_item:, day: nil, item_index: nil, total_items: nil)
        @item = item
        @parent_item = parent_item
        @day = day
        @item_index = item_index
        @total_items = total_items
      end

      def view_template
        div(
          id: "drawer_child_item_#{@item.id}",
          class: "flex items-center gap-2 p-2 rounded-lg border bg-card hover:bg-accent/50 transition-colors"
        ) do
          # Checkbox for completable items
          if @item.completable?
            render_checkbox
          end

          # Item title
          div(class: "flex-1 min-w-0") do
            title_classes = ["text-sm truncate"]
            title_classes << "line-through text-muted-foreground" if @item.done?
            p(class: title_classes.join(" ")) { @item.title }
          end

          # Move buttons
          div(class: "flex items-center gap-1") do
            day_is_closed = @day&.closed? || false

            # Move Up - can move if: day is open AND not at position 0
            can_move_up = !@item_index.nil? && @item_index > 0 && !day_is_closed
            render_move_button(:up, can_move_up)

            # Move Down - can move if: day is open AND not at last position
            can_move_down = !@item_index.nil? && !@total_items.nil? && @item_index < (@total_items - 1) && !day_is_closed
            render_move_button(:down, can_move_down)
          end
        end
      end

      private

      def render_checkbox
        form(
          action: toggle_state_item_path(@item),
          method: "post",
          data: {
            controller: "auto-submit",
            auto_submit_message_value: @item.done? ? "Marking as todo..." : "Marking as done...",
            turbo: "true"
          },
          class: "shrink-0"
        ) do
          csrf_token_field
          input(type: "hidden", name: "_method", value: "patch")
          input(type: "hidden", name: "state", value: @item.done? ? "todo" : "done")

          input(
            type: "checkbox",
            checked: @item.done?,
            class: "h-3.5 w-3.5 rounded border-gray-300 text-primary focus:ring-2 focus:ring-primary focus:ring-offset-2 cursor-pointer",
            data: { action: "change->auto-submit#submit" }
          )
        end
      end

      def render_move_button(direction, enabled)
        if enabled
          form(
            action: move_item_path(@item),
            method: "post",
            data: {
              controller: "form-loading",
              form_loading_message_value: "Moving item #{direction}...",
              turbo: "true"
            },
            class: "inline-block"
          ) do
            csrf_token_field
            input(type: "hidden", name: "_method", value: "patch")
            input(type: "hidden", name: "direction", value: direction.to_s)
            input(type: "hidden", name: "day_id", value: @day&.id) if @day

            button(
              type: "submit",
              class: "flex h-7 w-7 items-center justify-center rounded hover:bg-accent transition-colors"
            ) do
              render_arrow_icon(direction)
            end
          end
        else
          button(
            type: "button",
            disabled: true,
            class: "flex h-7 w-7 items-center justify-center rounded opacity-30 cursor-not-allowed"
          ) do
            render_arrow_icon(direction)
          end
        end
      end

      def render_arrow_icon(direction)
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16",
          height: "16",
          viewBox: "0 0 24 24",
          fill: "none",
          stroke: "currentColor",
          stroke_width: "2",
          stroke_linecap: "round",
          stroke_linejoin: "round"
        ) do |s|
          if direction == :up
            s.path(d: "m5 12 7-7 7 7")
            s.path(d: "M12 19V5")
          else
            s.path(d: "M12 5v14")
            s.path(d: "m19 12-7 7-7-7")
          end
        end
      end
    end
  end
end
