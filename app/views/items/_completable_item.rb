# frozen_string_literal: true

module Views
  module Items
    class CompletableItem < BaseItem
      def item_classes
        base_classes = "group flex items-center gap-2 rounded-lg border bg-card p-2.5 hover:bg-accent/50 transition-colors cursor-pointer w-full min-w-0 max-w-full overflow-hidden"

        # Add opacity for deferred, done, or dropped items
        if @record.deferred? || @record.done? || @record.dropped?
          "#{base_classes} opacity-60"
        else
          base_classes
        end
      end

      def render_icon
        render_checkbox
      end

      def render_content
        div(class: "flex-1 min-w-0 max-w-full overflow-hidden", style: "max-width: 100%; overflow: hidden; min-width: 0; flex: 1 1 0%;") do
          if @record.has_unfurled_url?
            render_unfurled_item
          else
            div(class: "truncate min-w-0 max-w-full w-full", style: "max-width: 100%; overflow: hidden; min-width: 0; width: 100%;") do
              title_classes = [ "text-sm truncate" ]
              title_classes << "line-through text-muted-foreground" if @record.done?
              p(class: title_classes.join(" ") + " w-full", style: "overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 100%; width: 100%; display: block; min-width: 0;") { @record.title }
            end
          end
        end
      end

      def render_badges
        # State badge for deferred or dropped items
        if @record.deferred? || @record.dropped?
          span(class: "shrink-0 rounded-full bg-muted px-2 py-0.5 text-xs text-muted-foreground") do
            @record.state.to_s
          end
        end

        # Recurring badge
        if @record.has_recurrence?
          span(class: "shrink-0 rounded-full bg-blue-500 text-white px-2 py-0.5 text-xs flex items-center gap-1") do
            # Small recycle icon
            render ::Components::Icon::Recycle.new(size: "12", class: "shrink-0")
            plain "recurring"
          end
        end

        # Notes indicator
        if @record.has_notes?
          span(class: "shrink-0 flex items-center justify-center h-5 w-5") do
            render ::Components::Icon::StickyNote.new(size: "14", class: "text-yellow-600 dark:text-yellow-400")
          end
        end
      end

      def stimulus_data
        {
          controller: "item",
          item_id_value: @record.id,
          item_day_id_value: @day&.id,
          item_list_id_value: @list&.id,
          item_is_public_list_value: @is_public_list,
          item_type_value: @record.item_type,
          action: "click->item#openSheet",
          day_move_target: "item"
        }
      end

      private

      def render_unfurled_item
        div(class: "flex gap-2 items-center min-w-0 w-full max-w-full", style: "max-width: 100%; overflow: hidden;") do
          # Thumbnail image
          if @record.preview_image.attached?
            img(
              src: view_context.url_for(@record.preview_image),
              class: "w-10 h-10 rounded object-cover shrink-0"
            )
          end

          # Title + description
          div(class: "flex-1 min-w-0 flex flex-col gap-0.5 overflow-hidden max-w-full", style: "max-width: 100%; overflow: hidden;") do
            title_classes = [ "text-sm truncate" ]
            title_classes << "line-through text-muted-foreground" if @record.done?

            # Clickable link - stop propagation to prevent drawer opening
            div(class: "truncate min-w-0 max-w-full", style: "max-width: 100%; overflow: hidden;") do
              a(
                href: @record.unfurled_url,
                target: "_blank",
                rel: "noopener noreferrer",
                class: title_classes.join(" ") + " hover:underline block truncate",
                style: "overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 100%; display: block;",
                data: { action: "click->item#stopPropagation" }
              ) { @record.title }
            end

            # Optional: Show description (truncated to 80 chars)
            if @record.unfurled_description.present?
              div(class: "truncate min-w-0 max-w-full", style: "max-width: 100%; overflow: hidden;") do
                p(class: "text-xs text-muted-foreground truncate", style: "overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 100%;") do
                  view_context.truncate(@record.unfurled_description, length: 80)
                end
              end
            end
          end
        end
      end

      def render_checkbox
        # ALWAYS use toggle_state endpoint for both days and lists
        # This ensures state changes go through set_done!/set_todo! methods
        toggle_path = if @list
          toggle_state_reusable_item_path(@record)
        else
          toggle_state_item_path(@record)
        end

        form(
          action: toggle_path,
          method: "post",
          data: {
            controller: "form-loading item",
            form_loading_message_value: @record.done? ? "Marking as todo..." : "Marking as done...",
            turbo_frame: "_top",
            action: "click->item#stopPropagation change->item#submitForm"
          },
          class: "shrink-0"
        ) do
          csrf_token_field
          input(type: "hidden", name: "_method", value: "patch")

          # Always use state param (not item[state])
          input(type: "hidden", name: "state", value: @record.done? ? "todo" : "done")

          # Add list_id for lists (day_id not needed for toggle_state)
          if @list
            input(type: "hidden", name: "list_id", value: @list.id)
          end

          # Custom styled checkbox wrapper
          label(class: "relative inline-flex items-center cursor-pointer shrink-0") do
            input(
              type: "checkbox",
              checked: @record.done?,
              disabled: @record.deferred?,
              class: "sr-only peer"
            )

            # Custom checkbox visual
            div(class: "h-4 w-4 rounded-sm border border-primary bg-background peer-checked:bg-primary peer-checked:border-primary peer-disabled:opacity-50 peer-disabled:cursor-not-allowed peer-focus-visible:ring-2 peer-focus-visible:ring-ring peer-focus-visible:ring-offset-2 flex items-center justify-center transition-colors") do
              # Checkmark SVG (conditionally rendered when checked)
              if @record.done?
                render ::Components::Icon::Check.new(size: "12", class: "h-3 w-3 text-primary-foreground", stroke_width: "3")
              end
            end
          end
        end
      end
    end
  end
end
