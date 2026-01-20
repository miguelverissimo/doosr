# frozen_string_literal: true

module Views
  module Items
    module Mobile
      class ActionsSheetButtons < ::Views::Base
        def initialize(item:, day: nil, item_index: nil, total_items: nil)
          @item = item
          @day = day
          @item_index = item_index
          @total_items = total_items
          @day_is_closed = @day&.closed? || false
        end

        def view_template
          div(id: "action_sheet_buttons_#{@item.id}", class: "space-y-3") do
            if @item.completable?
              render_primary_actions
              render_completable_actions
            elsif @item.section?
              render_section_actions
            end
          end
        end

        private

        def render_primary_actions
          # Row 1: left (complete, edit, drop, defer) | right (debug)
          div(class: "flex justify-between") do
            div(class: "flex gap-2") do
              # Complete/Uncomplete
              render_action_button(
                icon: @item.done? ? :circle : :check_circle,
                action: toggle_state_item_path(@item),
                method: "patch",
                params: { "state" => @item.done? ? "todo" : "done" },
                variant: :primary,
                disabled: @item.deferred? || @day_is_closed,
                loading_message: @item.done? ? "Marking as todo..." : "Marking as done..."
              )

              # Edit
              render_link_button(
                icon: :edit,
                href: edit_form_item_path(@item, day_id: @day&.id),
                disabled: @item.deferred? || @day_is_closed
              )

              # Drop/Undrop
              render_action_button(
                icon: @item.dropped? ? :rotate_ccw : :x,
                action: toggle_state_item_path(@item),
                method: "patch",
                params: { "state" => @item.dropped? ? "todo" : "dropped" },
                variant: :destructive,
                disabled: @item.deferred? || @day_is_closed,
                loading_message: @item.dropped? ? "Restoring..." : "Dropping..."
              )

              # Defer/Undefer
              if @item.deferred?
                render_action_button(
                  icon: :rotate_ccw,
                  action: undefer_item_path(@item),
                  method: "patch",
                  params: { "day_id" => @day&.id },
                  disabled: @day_is_closed,
                  loading_message: "Restoring..."
                )
              else
                render_link_button(
                  icon: :defer,
                  href: defer_options_item_path(@item, day_id: @day&.id),
                  disabled: @day_is_closed
                )
              end
            end

            div(class: "flex gap-2") do
              # Debug
              render_stimulus_button(
                icon: :bug,
                controller: "item",
                controller_values: { id: @item.id },
                action: "click->item#openDebug"
              )
            end
          end
        end

        def render_completable_actions
          render_secondary_actions
        end

        def render_secondary_actions
          # Row 2: left (recurrence, reminders) | right (reparent, move up, move down)
          div(class: "flex justify-between") do
            div(class: "flex gap-2") do
              # Recurrence
              render_link_button(
                icon: :recycle,
                href: recurrence_options_item_path(@item, day_id: @day&.id),
                disabled: @item.deferred? || @day_is_closed
              )

              # Reminders
              render_link_button(
                icon: :bell,
                href: reminders_item_path(@item, day_id: @day&.id),
                disabled: @item.deferred? || @day_is_closed
              )
            end

            div(class: "flex gap-2") do
              # Move/Reparent
              render_stimulus_button(
                icon: :move,
                controller: "item-move",
                controller_values: { item_id: @item.id, day_id: @day&.id },
                action: "click->item-move#startMoving",
                disabled: @item.deferred? || @day_is_closed
              )

              # Move up/down
              render_move_buttons_inline
            end
          end
        end

        def render_section_actions
          div(class: "flex justify-between") do
            div(class: "flex gap-2") do
              # Edit
              render_link_button(
                icon: :edit,
                href: edit_form_item_path(@item, day_id: @day&.id),
                disabled: @day_is_closed
              )
            end

            div(class: "flex gap-2") do
              # Move/Reparent
              render_stimulus_button(
                icon: :move,
                controller: "item-move",
                controller_values: { item_id: @item.id, day_id: @day&.id },
                action: "click->item-move#startMoving",
                disabled: @day_is_closed
              )

              # Move up/down
              render_move_buttons_inline

              # Debug
              render_stimulus_button(
                icon: :bug,
                controller: "item",
                controller_values: { id: @item.id },
                action: "click->item#openDebug"
              )
            end
          end
        end

        def render_move_buttons_inline
          can_move_up = @item_index && @item_index > 0 && !@day_is_closed
          can_move_down = @item_index && @total_items && @item_index < (@total_items - 1) && !@day_is_closed

          render_action_button(
            icon: :arrow_up,
            action: move_item_path(@item),
            method: "patch",
            params: { "direction" => "up", "day_id" => @day&.id },
            disabled: !can_move_up,
            loading_message: "Moving..."
          )

          render_action_button(
            icon: :arrow_down,
            action: move_item_path(@item),
            method: "patch",
            params: { "direction" => "down", "day_id" => @day&.id },
            disabled: !can_move_down,
            loading_message: "Moving..."
          )
        end

        def render_action_button(icon:, action:, method: "post", params: {}, disabled: false, variant: :outline, loading_message: "Processing...")
          if disabled
            render_disabled_button(icon: icon)
          else
            render RubyUI::Form.new(
              action: action,
              method: "post",
              data: {
                controller: "form-loading",
                form_loading_message_value: loading_message,
                turbo: "true"
              }
            ) do
              render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: form_authenticity_token)
              render RubyUI::Input.new(type: :hidden, name: "_method", value: method) if method != "post"

              params.each do |key, value|
                render RubyUI::Input.new(type: :hidden, name: key, value: value)
              end

              Button(variant: variant, size: :sm, class: "size-12") do
                icon_class = ::Components::Icon::Base.for(icon)
                render icon_class.new(size: "20")
              end
            end
          end
        end

        def render_link_button(icon:, href:, disabled: false)
          if disabled
            render_disabled_button(icon: icon)
          else
            Button(
              variant: :outline,
              size: :sm,
              class: "size-12",
              data: {
                controller: "drawer-back",
                drawer_back_url_value: href,
                action: "click->drawer-back#goBack"
              }
            ) do
              icon_class = ::Components::Icon::Base.for(icon)
              render icon_class.new(size: "20")
            end
          end
        end

        def render_stimulus_button(icon:, controller:, controller_values:, action:, disabled: false)
          if disabled
            render_disabled_button(icon: icon)
          else
            data_attrs = { controller: controller, action: action }
            controller_values.each do |key, value|
              data_attrs[:"#{controller.tr('-', '_')}_#{key}_value"] = value
            end

            Button(variant: :outline, size: :sm, class: "size-12", data: data_attrs) do
              icon_class = ::Components::Icon::Base.for(icon)
              render icon_class.new(size: "20")
            end
          end
        end

        def render_disabled_button(icon:)
          Button(variant: :outline, size: :sm, class: "size-12", disabled: true) do
            icon_class = ::Components::Icon::Base.for(icon)
            render icon_class.new(size: "20")
          end
        end
      end
    end
  end
end
