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
              render Components::Icon.new(name: :clock, size: "20")
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
            render Components::Icon.new(name: :edit, size: "20")
          end
        else
          a(
            href: edit_form_item_path(@item, day_id: @day&.id),
            data: { turbo_stream: true },
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
          ) do
            render Components::Icon.new(name: :edit, size: "20")
          end
        end

        # Recurrence
        if @item.deferred? || @day_is_closed
          button(
            type: "button",
            disabled: true,
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
          ) do
            render Components::Icon.new(name: :recycle, size: "20")
          end
        else
          a(
            href: recurrence_options_item_path(@item, day_id: @day&.id),
            data: { turbo_stream: true },
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
          ) do
            render Components::Icon.new(name: :recycle, size: "20")
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
            render Components::Icon.new(name: :move, size: "20")
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
            render Components::Icon.new(name: :move, size: "20")
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
          render Components::Icon.new(name: :bug, size: "20")
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
            render Components::Icon.new(name: :edit, size: "20")
          end
        else
          a(
            href: edit_form_item_path(@item, day_id: @day&.id),
            data: { turbo_stream: true },
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
          ) do
            render Components::Icon.new(name: :edit, size: "20")
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
            render Components::Icon.new(name: :move, size: "20")
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
            render Components::Icon.new(name: :move, size: "20")
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
          render Components::Icon.new(name: :bug, size: "20")
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
            render Components::Icon.new(name: icon, size: "20")
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
              render Components::Icon.new(name: icon, size: "20")
            end
          end
        end
      end

      def render_icon(name, size: "24")
        render Components::Icon.new(name: name, size: size)
      end
    end
  end
end
