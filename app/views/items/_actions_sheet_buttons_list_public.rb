# frozen_string_literal: true

module Views
  module Items
    class ActionsSheetButtonsListPublic < ::Views::Base
      def initialize(item:, list: nil, item_index: nil, total_items: nil, is_editable: false)
        @item = item
        @list = list
        @item_index = item_index
        @total_items = total_items
        @is_editable = is_editable
      end

      def view_template
        div(id: "action_sheet_buttons_#{@item.id}", class: "flex items-center justify-between gap-2") do
          # Left side - primary actions
          div(class: "flex items-center gap-2") do
            if @item.reusable?
              render_reusable_primary_actions
            elsif @item.section?
              render_section_primary_actions
            end
          end

          # Right side - utility actions
          div(class: "flex items-center gap-2") do
            if @item.reusable?
              render_reusable_utility_actions
            elsif @item.section?
              render_section_utility_actions
            end
          end
        end
      end

      private

      def render_reusable_primary_actions
        # Complete/Uncomplete
        render_icon_button(
          icon: @item.done? ? :circle : :check_circle,
          action: toggle_state_reusable_item_path(@item),
          method: "patch",
          params: { "state" => @item.done? ? "todo" : "done", "list_id" => @list&.id },
          variant: :primary,
          disabled: !@is_editable,
          loading_message: @item.done? ? "Marking as todo..." : "Marking as done..."
        )

        # Edit
        if @is_editable
          a(
            href: edit_form_reusable_item_path(@item, list_id: @list&.id),
            data: { turbo_stream: true },
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
          ) do
            render ::Components::Icon::Edit.new(size: "20")
          end
        else
          button(
            type: "button",
            disabled: true,
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
          ) do
            render ::Components::Icon::Edit.new(size: "20")
          end
        end
      end

      def render_reusable_utility_actions
        # Reparent/Move
        if @is_editable
          button(
            type: "button",
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors",
            data: {
              controller: "item-move",
              item_move_item_id_value: @item.id,
              item_move_list_id_value: @list&.id,
              action: "click->item-move#startMoving"
            }
          ) do
            render ::Components::Icon::Move.new(size: "20")
          end
        else
          button(
            type: "button",
            disabled: true,
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
          ) do
            render ::Components::Icon::Move.new(size: "20")
          end
        end

        # Move Up
        can_move_up = @item_index && @item_index > 0 && @is_editable
        render_icon_button(
          icon: :arrow_up,
          action: move_reusable_item_path(@item),
          method: "patch",
          params: { "direction" => "up", "list_id" => @list&.id },
          disabled: !can_move_up,
          loading_message: "Moving item up..."
        )

        # Move Down
        can_move_down = @item_index && @total_items && @item_index < (@total_items - 1) && @is_editable
        render_icon_button(
          icon: :arrow_down,
          action: move_reusable_item_path(@item),
          method: "patch",
          params: { "direction" => "down", "list_id" => @list&.id },
          disabled: !can_move_down,
          loading_message: "Moving item down..."
        )

        # Debug
        button(
          type: "button",
          class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors",
          data: {
            controller: "item",
            item_id_value: @item.id,
            action: "click->item#openDebug"
          }
        ) do
          render ::Components::Icon::Bug.new(size: "20")
        end
      end

      def render_section_primary_actions
        # Edit
        if @is_editable
          a(
            href: edit_form_reusable_item_path(@item, list_id: @list&.id),
            data: { turbo_stream: true },
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
          ) do
            render ::Components::Icon::Edit.new(size: "20")
          end
        else
          button(
            type: "button",
            disabled: true,
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
          ) do
            render ::Components::Icon::Edit.new(size: "20")
          end
        end
      end

      def render_section_utility_actions
        # Reparent/Move
        if @is_editable
          button(
            type: "button",
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors",
            data: {
              controller: "item-move",
              item_move_item_id_value: @item.id,
              item_move_list_id_value: @list&.id,
              action: "click->item-move#startMoving"
            }
          ) do
            render ::Components::Icon::Move.new(size: "20")
          end
        else
          button(
            type: "button",
            disabled: true,
            class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
          ) do
            render ::Components::Icon::Move.new(size: "20")
          end
        end

        # Move Up
        can_move_up = @item_index && @item_index > 0 && @is_editable
        render_icon_button(
          icon: :arrow_up,
          action: move_reusable_item_path(@item),
          method: "patch",
          params: { "direction" => "up", "list_id" => @list&.id },
          disabled: !can_move_up,
          loading_message: "Moving item up..."
        )

        # Move Down
        can_move_down = @item_index && @total_items && @item_index < (@total_items - 1) && @is_editable
        render_icon_button(
          icon: :arrow_down,
          action: move_reusable_item_path(@item),
          method: "patch",
          params: { "direction" => "down", "list_id" => @list&.id },
          disabled: !can_move_down,
          loading_message: "Moving item down..."
        )

        # Debug
        button(
          type: "button",
          class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors",
          data: {
            controller: "item",
            item_id_value: @item.id,
            action: "click->item#openDebug"
          }
        ) do
          render ::Components::Icon::Bug.new(size: "20")
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
            icon_class = ::Components::Icon::Base.for(icon)
              render icon_class.new(size: "20")
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
              icon_class = ::Components::Icon::Base.for(icon)
              render icon_class.new(size: "20")
            end
          end
        end
      end

      def render_icon(name, size: "24")
        icon_class = ::Components::Icon::Base.for(name)
        render icon_class.new(size: size)
      end
    end
  end
end
