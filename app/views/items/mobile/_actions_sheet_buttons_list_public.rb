# frozen_string_literal: true

module Views
  module Items
    module Mobile
      class ActionsSheetButtonsListPublic < ::Views::Base
        def initialize(item:, list: nil, item_index: nil, total_items: nil, is_editable: false)
          @item = item
          @list = list
          @item_index = item_index
          @total_items = total_items
          @is_editable = is_editable
        end

        def view_template
          div(id: "action_sheet_buttons_#{@item.id}", class: "space-y-3") do
            if @item.reusable?
              render_reusable_actions
            elsif @item.section?
              render_section_actions
            end
          end
        end

        private

        def render_reusable_actions
          div(class: "grid grid-cols-4 gap-2") do
            # Complete/Uncomplete
            render_action_button(
              icon: @item.done? ? :circle : :check_circle,
              label: @item.done? ? "Undo" : "Done",
              action: toggle_state_reusable_item_path(@item),
              method: "patch",
              params: { "state" => @item.done? ? "todo" : "done", "list_id" => @list&.id },
              variant: :primary,
              disabled: !@is_editable,
              loading_message: @item.done? ? "Marking as todo..." : "Marking as done..."
            )

            # Edit
            render_link_button(
              icon: :edit,
              label: "Edit",
              href: edit_form_reusable_item_path(@item, list_id: @list&.id),
              disabled: !@is_editable
            )

            # Move/Reparent
            render_stimulus_button(
              icon: :move,
              label: "Move",
              controller: "item-move",
              controller_values: { item_id: @item.id, list_id: @list&.id },
              action: "click->item-move#startMoving",
              disabled: !@is_editable
            )

            # Debug
            render_stimulus_button(
              icon: :bug,
              label: "Debug",
              controller: "item",
              controller_values: { id: @item.id },
              action: "click->item#openDebug"
            )
          end

          render_move_buttons
        end

        def render_section_actions
          div(class: "grid grid-cols-4 gap-2") do
            # Edit
            render_link_button(
              icon: :edit,
              label: "Edit",
              href: edit_form_reusable_item_path(@item, list_id: @list&.id),
              disabled: !@is_editable
            )

            # Move/Reparent
            render_stimulus_button(
              icon: :move,
              label: "Move",
              controller: "item-move",
              controller_values: { item_id: @item.id, list_id: @list&.id },
              action: "click->item-move#startMoving",
              disabled: !@is_editable
            )

            # Debug
            render_stimulus_button(
              icon: :bug,
              label: "Debug",
              controller: "item",
              controller_values: { id: @item.id },
              action: "click->item#openDebug"
            )

            div
          end

          render_move_buttons
        end

        def render_move_buttons
          can_move_up = @item_index && @item_index > 0 && @is_editable
          can_move_down = @item_index && @total_items && @item_index < (@total_items - 1) && @is_editable

          div(class: "flex gap-2") do
            div(class: "flex-1") do
              render_action_button(
                icon: :arrow_up,
                label: "Move up",
                action: move_reusable_item_path(@item),
                method: "patch",
                params: { "direction" => "up", "list_id" => @list&.id },
                disabled: !can_move_up,
                loading_message: "Moving...",
                full_width: true
              )
            end

            div(class: "flex-1") do
              render_action_button(
                icon: :arrow_down,
                label: "Move down",
                action: move_reusable_item_path(@item),
                method: "patch",
                params: { "direction" => "down", "list_id" => @list&.id },
                disabled: !can_move_down,
                loading_message: "Moving...",
                full_width: true
              )
            end
          end
        end

        def render_action_button(icon:, label:, action:, method: "post", params: {}, disabled: false, variant: :outline, loading_message: "Processing...", full_width: false)
          if disabled
            render_disabled_button(icon: icon, label: label, full_width: full_width)
          else
            render RubyUI::Form.new(
              action: action,
              method: "post",
              data: {
                controller: "form-loading",
                form_loading_message_value: loading_message,
                turbo: "true"
              },
              class: full_width ? "w-full" : ""
            ) do
              render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: form_authenticity_token)
              render RubyUI::Input.new(type: :hidden, name: "_method", value: method) if method != "post"

              params.each do |key, value|
                render RubyUI::Input.new(type: :hidden, name: key, value: value)
              end

              Button(variant: variant, size: :sm, class: "#{full_width ? 'flex-1 h-12' : 'size-12'} flex-col gap-1") do
                icon_class = ::Components::Icon::Base.for(icon)
                render icon_class.new(size: "20")
                span(class: "text-xs") { label } unless full_width
              end
            end
          end
        end

        def render_link_button(icon:, label:, href:, disabled: false)
          if disabled
            render_disabled_button(icon: icon, label: label)
          else
            Button(
              variant: :outline,
              size: :sm,
              class: "size-12 flex-col gap-1",
              data: {
                controller: "drawer-back",
                drawer_back_url_value: href,
                action: "click->drawer-back#goBack"
              }
            ) do
              icon_class = ::Components::Icon::Base.for(icon)
              render icon_class.new(size: "20")
              span(class: "text-xs") { label }
            end
          end
        end

        def render_stimulus_button(icon:, label:, controller:, controller_values:, action:, disabled: false)
          if disabled
            render_disabled_button(icon: icon, label: label)
          else
            data_attrs = { controller: controller, action: action }
            controller_values.each do |key, value|
              data_attrs[:"#{controller.tr('-', '_')}_#{key}_value"] = value
            end

            Button(variant: :outline, size: :sm, class: "size-12 flex-col gap-1", data: data_attrs) do
              icon_class = ::Components::Icon::Base.for(icon)
              render icon_class.new(size: "20")
              span(class: "text-xs") { label }
            end
          end
        end

        def render_disabled_button(icon:, label:, full_width: false)
          Button(variant: :outline, size: :sm, class: "#{full_width ? 'flex-1 h-12' : 'size-12'} flex-col gap-1", disabled: true) do
            icon_class = ::Components::Icon::Base.for(icon)
            render icon_class.new(size: "20")
            span(class: "text-xs") { label } unless full_width
          end
        end
      end
    end
  end
end
