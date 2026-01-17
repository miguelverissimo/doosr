# frozen_string_literal: true

module Views
  module Items
    class ActionsSheetButtons < ::Views::Base
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
        # Complete/Uncomplete - PRIMARY button (filled)
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
            render_icon_button(
              icon: :clock,
              href: defer_options_item_path(@item, day_id: @day&.id),
              params: { data: { turbo_stream: true } }
            )
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
        render_icon_button(
          icon: :edit,
          href: edit_form_item_path(@item, day_id: @day&.id),
          params: { data: { turbo_stream: true } },
          disabled: @item.deferred? || @day_is_closed
        )

        # Recurrence
        render_icon_button(
          icon: :recycle,
          href: recurrence_options_item_path(@item, day_id: @day&.id),
          params: { data: { turbo_stream: true } },
          disabled: @item.deferred? || @day_is_closed
        )

        # Reminders
        render_icon_button(
          icon: :bell,
          href: reminders_item_path(@item, day_id: @day&.id),
          params: { data: { turbo_stream: true } },
          disabled: @item.deferred? || @day_is_closed
        )
      end

      def render_completable_utility_actions
        # Reparent/Move
        render_stimulus_icon_button(
          icon: :move,
          controller: "item-move",
          controller_values: { item_id: @item.id, day_id: @day&.id },
          action: "click->item-move#startMoving",
          disabled: @item.deferred? || @day_is_closed
        )

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

        # Debug
        render_stimulus_icon_button(
          icon: :bug,
          controller: "item",
          controller_values: { id: @item.id },
          action: "click->item#openDebug"
        )
      end

      def render_section_primary_actions
        # Edit
        render_icon_button(
          icon: :edit,
          href: edit_form_item_path(@item, day_id: @day&.id),
          params: { data: { turbo_stream: true } },
          disabled: @day_is_closed
        )

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
        # Reparent/Move
        render_stimulus_icon_button(
          icon: :move,
          controller: "item-move",
          controller_values: { item_id: @item.id, day_id: @day&.id },
          action: "click->item-move#startMoving",
          disabled: @day_is_closed
        )

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

        # Debug
        render_stimulus_icon_button(
          icon: :bug,
          controller: "item",
          controller_values: { id: @item.id },
          action: "click->item#openDebug"
        )
      end

      def render_icon_button(icon:, action: nil, href: nil, method: "post", params: {}, disabled: false, variant: :outline, loading_message: "Processing...")
        if disabled
          render_disabled_icon_button do
            icon_class = ::Components::Icon::Base.for(icon)
            render icon_class.new(size: "20")
          end
        elsif href
          # Use Stimulus controller to fetch turbo stream and render it
          Button(
            variant: :outline,
            size: :lg,
            icon: true,
            type: "button",
            data: {
              controller: "drawer-back",
              drawer_back_url_value: href,
              action: "click->drawer-back#goBack"
            }
          ) do
            icon_class = ::Components::Icon::Base.for(icon)
            render icon_class.new(size: "20")
          end
        else
          # Render as form
          render RubyUI::Form.new(
            action: action,
            method: "post",
            data: {
              controller: "form-loading",
              form_loading_message_value: loading_message,
              turbo: "true"
            },
            class: "inline-block"
          ) do
            render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: helpers.form_authenticity_token)
            render RubyUI::Input.new(type: :hidden, name: "_method", value: method) if method != "post"

            params.each do |key, value|
              render RubyUI::Input.new(type: :hidden, name: key, value: value) unless key == :data
            end

            # :primary = filled purple, :destructive = filled red, :outline = border only
            Button(variant: variant, size: :lg, icon: true) do
              icon_class = ::Components::Icon::Base.for(icon)
              render icon_class.new(size: "20")
            end
          end
        end
      end

      def render_stimulus_icon_button(icon:, controller:, controller_values:, action:, disabled: false)
        if disabled
          render_disabled_icon_button do
            icon_class = ::Components::Icon::Base.for(icon)
            render icon_class.new(size: "20")
          end
        else
          data_attrs = { controller: controller, action: action }
          controller_values.each do |key, value|
            data_attrs[:"#{controller.tr('-', '_')}_#{key}_value"] = value
          end

          Button(variant: :outline, size: :lg, icon: true, data: data_attrs) do
            icon_class = ::Components::Icon::Base.for(icon)
            render icon_class.new(size: "20")
          end
        end
      end

      def render_disabled_icon_button(&block)
        Button(variant: :outline, size: :lg, icon: true, disabled: true, &block)
      end

      def render_icon(name, size: "24")
        icon_class = ::Components::Icon::Base.for(name)
        render icon_class.new(size: size)
      end
    end
  end
end
