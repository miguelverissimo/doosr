# frozen_string_literal: true

module Views
  module Items
    class Item < ::Views::Base
      def initialize(item:, day: nil, list: nil, is_public_list: false)
        @item = item
        @day = day
        @list = list
        @is_public_list = is_public_list
      end

      def view_template
        div(
          id: "item_#{@item.id}",
          class: item_classes,
          data: {
            controller: "item",
            item_id_value: @item.id,
            item_day_id_value: @day&.id,
            item_list_id_value: @list&.id,
            item_is_public_list_value: @is_public_list,
            item_type_value: @item.item_type,
            action: "click->item#openSheet",
            day_move_target: "item"
          }
        ) do
          # Checkbox for completable and reusable items
          if @item.can_be_completed?
            render_checkbox
          elsif @item.section?
            render_section_icon
          end

          # Item title
          div(class: "flex-1 min-w-0") do
            if @item.section?
              h3(class: "font-semibold text-sm truncate") { @item.title }
            else
              title_classes = [ "text-sm truncate" ]
              title_classes << "line-through text-muted-foreground" if @item.done?
              p(class: title_classes.join(" ")) { @item.title }
            end
          end

          # State badge for deferred or dropped items
          if @item.deferred? || @item.dropped?
            span(class: "shrink-0 rounded-full bg-muted px-2 py-0.5 text-xs text-muted-foreground") do
              @item.state.to_s
            end
          end

          # Recurring badge
          if @item.has_recurrence?
            span(class: "shrink-0 rounded-full bg-blue-500 text-white px-2 py-0.5 text-xs flex items-center gap-1") do
              # Small recycle icon
              render ::Components::Icon::Recycle.new(size: "12", class: "shrink-0")
              plain "recurring"
            end
          end

          # Actions menu (hidden, shown on hover)
          div(class: "opacity-0 group-hover:opacity-100 transition-opacity flex items-center gap-1") do
            Button(variant: :ghost, icon: true, size: :sm, class: "h-7 w-7") do
              render ::Components::Icon::MoreVertical.new(size: "14", class: "shrink-0")
            end
          end
        end
      end

      private

      def item_classes
        base_classes = case @item.item_type.to_sym
        when :completable
          "group flex items-center gap-2 rounded-lg border bg-card p-2.5 hover:bg-accent/50 transition-colors cursor-pointer"
        when :section
          "flex w-full cursor-pointer items-center gap-2 rounded-md bg-muted p-3 text-left transition-colors hover:bg-muted/85"
        else
          "flex w-full cursor-pointer items-center gap-2 rounded-md border bg-card p-3 text-left transition-colors hover:bg-muted/50"
        end

        # Add opacity for deferred, done, or dropped items
        if @item.deferred? || @item.done? || @item.dropped?
          "#{base_classes} opacity-60"
        else
          base_classes
        end
      end

      def render_checkbox
        # ALWAYS use toggle_state endpoint for both days and lists
        # This ensures state changes go through set_done!/set_todo! methods
        toggle_path = if @list
          toggle_state_reusable_item_path(@item)
        else
          toggle_state_item_path(@item)
        end

        form(
          action: toggle_path,
          method: "post",
          data: {
            controller: "form-loading item",
            form_loading_message_value: @item.done? ? "Marking as todo..." : "Marking as done...",
            turbo_frame: "_top",
            action: "click->item#stopPropagation change->item#submitForm"
          },
          class: "shrink-0"
        ) do
          csrf_token_field
          input(type: "hidden", name: "_method", value: "patch")

          # Always use state param (not item[state])
          input(type: "hidden", name: "state", value: @item.done? ? "todo" : "done")

          # Add list_id for lists (day_id not needed for toggle_state)
          if @list
            input(type: "hidden", name: "list_id", value: @list.id)
          end

          # Custom styled checkbox wrapper
          label(class: "relative inline-flex items-center cursor-pointer shrink-0") do
            input(
              type: "checkbox",
              checked: @item.done?,
              disabled: @item.deferred?,
              class: "sr-only peer"
            )

            # Custom checkbox visual
            div(class: "h-4 w-4 rounded-sm border border-primary bg-background peer-checked:bg-primary peer-checked:border-primary peer-disabled:opacity-50 peer-disabled:cursor-not-allowed peer-focus-visible:ring-2 peer-focus-visible:ring-ring peer-focus-visible:ring-offset-2 flex items-center justify-center transition-colors") do
              # Checkmark SVG (conditionally rendered when checked)
              if @item.done?
                render ::Components::Icon::Check.new(size: "12", class: "h-3 w-3 text-primary-foreground", stroke_width: "3")
              end
            end
          end
        end
      end

      def render_section_icon
        div(class: "flex h-3.5 w-3.5 items-center justify-center shrink-0") do
          render ::Components::Icon::Hash.new(size: "14", class: "text-muted-foreground")
        end
      end
    end
  end
end
