# frozen_string_literal: true

module Views
  module Items
    class ActionsSheetButtons < Views::Base
      def initialize(item:, day: nil, item_index: nil, total_items: nil)
        @item = item
        @day = day
        @item_index = item_index
        @total_items = total_items
        @day_is_closed = @day&.closed? || false
      end

      def view_template
        div(id: "action_sheet_buttons_#{@item.id}", class: "flex items-center justify-between gap-2") do
          # Left side - primary actions
          div(class: "flex items-center gap-2") do
            if @item.completable?
              render_completable_primary_actions
            elsif @item.section?
              render_section_primary_actions
            end
          end

          # Right side - utility actions
          div(class: "flex items-center gap-2") do
            if @item.completable?
              render_completable_utility_actions
            elsif @item.section?
              render_section_utility_actions
            end
          end
        end
      end

      private

      def render_completable_primary_actions
        # Complete/Uncomplete
        render_icon_button(
          icon: @item.done? ? :circle : :check_circle,
          action: toggle_state_item_path(@item),
          method: "patch",
          params: { "state" => @item.done? ? "todo" : "done" },
          variant: :primary,
          disabled: @item.deferred? || @day_is_closed,
          loading_message: @item.done? ? "Marking as todo..." : "Marking as done..."
        )

        # Defer/Undefer
        if @item.deferred?
          # Show undefer button when item is deferred (unless day is closed)
          if @day_is_closed
            render_icon_button(
              icon: :rotate_ccw,
              disabled: true
            )
          else
            render_icon_button(
              icon: :rotate_ccw,
              action: undefer_item_path(@item),
              method: "patch",
              params: { "day_id" => @day&.id },
              variant: :default,
              loading_message: "Restoring item..."
            )
          end
        else
          # Show defer button when item is not deferred (unless day is closed)
          if @day_is_closed
            render_icon_button(
              icon: :clock,
              disabled: true
            )
          else
            a(
              href: defer_options_item_path(@item, day_id: @day&.id),
              data: { turbo_stream: true },
              class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
            ) do
              render_icon(:clock, size: "20")
            end
          end
        end

        # Drop/Undrop
        render_icon_button(
          icon: @item.dropped? ? :rotate_ccw : :x,
          action: toggle_state_item_path(@item),
          method: "patch",
          params: { "state" => @item.dropped? ? "todo" : "dropped" },
          variant: :destructive,
          disabled: @item.deferred? || @day_is_closed,
          loading_message: @item.dropped? ? "Restoring item..." : "Dropping item..."
        )

        # Edit
        if @item.deferred? || @day_is_closed
          button(
            type: "button",
            disabled: true,
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
          ) do
            render_icon(:edit, size: "20")
          end
        else
          a(
            href: edit_form_item_path(@item, day_id: @day&.id),
            data: { turbo_stream: true },
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
          ) do
            render_icon(:edit, size: "20")
          end
        end

        # Recurrence
        if @item.deferred? || @day_is_closed
          button(
            type: "button",
            disabled: true,
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
          ) do
            render_icon(:recycle, size: "20")
          end
        else
          a(
            href: recurrence_options_item_path(@item, day_id: @day&.id),
            data: { turbo_stream: true },
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
          ) do
            render_icon(:recycle, size: "20")
          end
        end
      end

      def render_completable_utility_actions
        # Reparent/Move - disabled for deferred items or closed days
        if @item.deferred? || @day_is_closed
          button(
            type: "button",
            disabled: true,
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
          ) do
            render_icon(:move, size: "20")
          end
        else
          button(
            type: "button",
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors",
            data: {
              controller: "item-move",
              item_move_item_id_value: @item.id,
              item_move_day_id_value: @day&.id,
              action: "click->item-move#startMoving"
            }
          ) do
            render_icon(:move, size: "20")
          end
        end

        # Move Up - can move if: day is open AND not at index 0
        can_move_up = @item_index && @item_index > 0 && !@day_is_closed
        render_icon_button(
          icon: :arrow_up,
          action: move_item_path(@item),
          method: "patch",
          params: { "direction" => "up", "day_id" => @day&.id },
          disabled: !can_move_up,
          loading_message: "Moving item up..."
        )

        # Move Down - can move if: day is open AND not at last position
        can_move_down = @item_index && @total_items && @item_index < (@total_items - 1) && !@day_is_closed
        render_icon_button(
          icon: :arrow_down,
          action: move_item_path(@item),
          method: "patch",
          params: { "direction" => "down", "day_id" => @day&.id },
          disabled: !can_move_down,
          loading_message: "Moving item down..."
        )

        # Debug - ALWAYS ACTIVE
        button(
          type: "button",
          class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors",
          data: {
            controller: "item",
            item_id_value: @item.id,
            action: "click->item#openDebug"
          }
        ) do
          render_icon(:bug, size: "20")
        end
      end

      def render_section_primary_actions
        # Edit
        if @day_is_closed
          button(
            type: "button",
            disabled: true,
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
          ) do
            render_icon(:edit, size: "20")
          end
        else
          a(
            href: edit_form_item_path(@item, day_id: @day&.id),
            data: { turbo_stream: true },
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
          ) do
            render_icon(:edit, size: "20")
          end
        end

        # Drop (placeholder)
        render_icon_button(
          icon: :x,
          disabled: true,
          variant: :destructive
        )

        # Reparent (placeholder)
        render_icon_button(
          icon: :git_branch,
          disabled: true
        )
      end

      def render_section_utility_actions
        # Reparent/Move - disabled for closed days
        if @day_is_closed
          button(
            type: "button",
            disabled: true,
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
          ) do
            render_icon(:move, size: "20")
          end
        else
          button(
            type: "button",
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors",
            data: {
              controller: "item-move",
              item_move_item_id_value: @item.id,
              item_move_day_id_value: @day&.id,
              action: "click->item-move#startMoving"
            }
          ) do
            render_icon(:move, size: "20")
          end
        end

        # Move Up - can move if: day is open AND not at index 0
        can_move_up = @item_index && @item_index > 0 && !@day_is_closed
        render_icon_button(
          icon: :arrow_up,
          action: move_item_path(@item),
          method: "patch",
          params: { "direction" => "up", "day_id" => @day&.id },
          disabled: !can_move_up,
          loading_message: "Moving item up..."
        )

        # Move Down - can move if: day is open AND not at last position
        can_move_down = @item_index && @total_items && @item_index < (@total_items - 1) && !@day_is_closed
        render_icon_button(
          icon: :arrow_down,
          action: move_item_path(@item),
          method: "patch",
          params: { "direction" => "down", "day_id" => @day&.id },
          disabled: !can_move_down,
          loading_message: "Moving item down..."
        )

        # Debug - ALWAYS ACTIVE
        button(
          type: "button",
          class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors",
          data: {
            controller: "item",
            item_id_value: @item.id,
            action: "click->item#openDebug"
          }
        ) do
          render_icon(:bug, size: "20")
        end
      end

      def render_icon_button(icon:, action: nil, method: "post", params: {}, disabled: false, variant: :default, loading_message: "Processing...")
        button_classes = case variant
        when :primary
          "flex h-10 w-10 items-center justify-center rounded-lg bg-primary text-primary-foreground hover:bg-primary/90 transition-colors"
        when :destructive
          "flex h-10 w-10 items-center justify-center rounded-lg border border-destructive text-destructive hover:bg-destructive hover:text-destructive-foreground transition-colors"
        else
          "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
        end

        if disabled
          button(
            type: "button",
            disabled: true,
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
          ) do
            render_icon(icon, size: "20")
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

            button(
              type: "submit",
              class: button_classes
            ) do
              render_icon(icon, size: "20")
            end
          end
        end
      end

      def render_icon(name, size: "24")
        icons = {
          check_circle: -> do
            svg(xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
              s.path(d: "M22 11.08V12a10 10 0 1 1-5.93-9.14")
              s.polyline(points: "22 4 12 14.01 9 11.01")
            end
          end,
          circle: -> do
            svg(xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
              s.circle(cx: "12", cy: "12", r: "10")
            end
          end,
          clock: -> do
            svg(xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
              s.circle(cx: "12", cy: "12", r: "10")
              s.polyline(points: "12 6 12 12 16 14")
            end
          end,
          x: -> do
            svg(xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
              s.path(d: "M18 6 6 18")
              s.path(d: "m6 6 12 12")
            end
          end,
          rotate_ccw: -> do
            svg(xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
              s.path(d: "M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8")
              s.path(d: "M3 3v5h5")
            end
          end,
          edit: -> do
            svg(xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
              s.path(d: "M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z")
              s.path(d: "m15 5 4 4")
            end
          end,
          git_branch: -> do
            svg(xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
              s.line(x1: "6", x2: "6", y1: "3", y2: "15")
              s.circle(cx: "18", cy: "6", r: "3")
              s.circle(cx: "6", cy: "18", r: "3")
              s.path(d: "M18 9a9 9 0 0 1-9 9")
            end
          end,
          arrow_up: -> do
            svg(xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
              s.path(d: "m5 12 7-7 7 7")
              s.path(d: "M12 19V5")
            end
          end,
          arrow_down: -> do
            svg(xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
              s.path(d: "M12 5v14")
              s.path(d: "m19 12-7 7-7-7")
            end
          end,
          bug: -> do
            svg(xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
              s.path(d: "m8 2 1.88 1.88")
              s.path(d: "M14.12 3.88 16 2")
              s.path(d: "M9 7.13v-1a3.003 3.003 0 1 1 6 0v1")
              s.path(d: "M12 20c-3.3 0-6-2.7-6-6v-3a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v3c0 3.3-2.7 6-6 6")
              s.path(d: "M12 20v-9")
              s.path(d: "M6.53 9C4.6 8.8 3 7.1 3 5")
              s.path(d: "M6 13H2")
              s.path(d: "M3 21c0-2.1 1.7-3.9 3.8-4")
              s.path(d: "M20.97 5c0 2.1-1.6 3.8-3.5 4")
              s.path(d: "M22 13h-4")
              s.path(d: "M17.2 17c2.1.1 3.8 1.9 3.8 4")
            end
          end,
          move: -> do
            svg(xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
              s.polyline(points: "5 9 2 12 5 15")
              s.polyline(points: "9 5 12 2 15 5")
              s.polyline(points: "15 19 12 22 9 19")
              s.polyline(points: "19 9 22 12 19 15")
              s.line(x1: "2", x2: "22", y1: "12", y2: "12")
              s.line(x1: "12", x2: "12", y1: "2", y2: "22")
            end
          end,
          recycle: -> do
            svg(xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round", class: "lucide lucide-recycle-icon lucide-recycle") do |s|
              s.path(d: "M7 19H4.815a1.83 1.83 0 0 1-1.57-.881 1.785 1.785 0 0 1-.004-1.784L7.196 9.5")
              s.path(d: "M11 19h8.203a1.83 1.83 0 0 0 1.556-.89 1.784 1.784 0 0 0 0-1.775l-1.226-2.12")
              s.path(d: "m14 16-3 3 3 3")
              s.path(d: "M8.293 13.596 7.196 9.5 3.1 10.598")
              s.path(d: "m9.344 5.811 1.093-1.892A1.83 1.83 0 0 1 11.985 3a1.784 1.784 0 0 1 1.546.888l3.943 6.843")
              s.path(d: "m13.378 9.633 4.096 1.098 1.097-4.096")
            end
          end
        }

        icons[name]&.call
      end
    end
  end
end
