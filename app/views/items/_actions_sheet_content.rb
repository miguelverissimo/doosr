# frozen_string_literal: true

module Views
  module Items
    class ActionsSheetContent < Views::Base
      def initialize(item:, day: nil, list: nil, item_index: nil, total_items: nil, is_public_list: false, is_editable: false)
        @item = item
        @day = day
        @list = list
        @item_index = item_index
        @total_items = total_items
        @is_public_list = is_public_list
        @is_editable = is_editable
      end

      def view_template
        # Just render the content that goes inside the existing sheet
        div(id: "sheet_content_area") do
          SheetHeader do
            SheetTitle(class: "text-left") { @item.title }
            SheetDescription(class: "text-left text-xs text-muted-foreground") do
              "#{@item.item_type.titleize} • #{@item.state.titleize}"
            end
          end

          SheetMiddle(class: "py-4 space-y-4") do
            # Action buttons - FIRST - render appropriate version based on context
            render_action_buttons

            # Add child item form - SECOND
            render_child_item_form

            # Nested items section - THIRD
            render_nested_items
          end
        end
      end

      private

      def render_action_buttons
        # Determine which buttons component to render based on context
        if @list
          # List context - use list-specific buttons
          if @is_public_list
            # Public list view - limited actions
            render Views::Items::ActionsSheetButtonsListPublic.new(
              item: @item,
              list: @list,
              item_index: @item_index,
              total_items: @total_items,
              is_editable: @is_editable
            )
          else
            # Owner view - full actions
            render Views::Items::ActionsSheetButtonsListOwner.new(
              item: @item,
              list: @list,
              item_index: @item_index,
              total_items: @total_items
            )
          end
        else
          # Day context - use original day buttons
          render Views::Items::ActionsSheetButtons.new(
            item: @item,
            day: @day,
            item_index: @item_index,
            total_items: @total_items
          )
        end
      end

      def render_child_item_form
        div(class: "space-y-2") do
          # Error container for form errors
          div(id: "child_item_form_errors_#{@item.id}")

          # Add child item form
          form(
            action: items_path,
            method: "post",
            data: {
              controller: "item-form",
              action: "submit->item-form#submit turbo:submit-end->item-form#clearForm",
              turbo: "true"
            },
            class: "flex items-center gap-2"
          ) do
            csrf_token_field
            input(type: "hidden", name: "parent_item_id", value: @item.id)
            input(type: "hidden", name: "day_id", value: @day&.id) if @day

            # In lists, nested items should be reusable by default
            # In days, nested items should be completable by default
            default_type = @list ? "reusable" : "completable"
            input(
              type: "hidden",
              name: "item[item_type]",
              value: default_type,
              data: { item_form_target: "itemType" }
            )

            Input(
              type: "text",
              name: "item[title]",
              placeholder: "Add an item...",
              class: "flex-1 text-sm h-9",
              data: { item_form_target: "titleInput" },
              required: true
            )

            # Type selector button - use appropriate cycle method
            Button(
              type: :button,
              variant: :ghost,
              icon: true,
              size: :sm,
              class: "shrink-0 h-9 w-9",
              data: { action: @list ? "click->item-form#cycleListType" : "click->item-form#cycleType" }
            ) do
              svg(
                xmlns: "http://www.w3.org/2000/svg",
                class: "h-4 w-4",
                viewBox: "0 0 24 24",
                fill: "none",
                stroke: "currentColor",
                stroke_width: "2",
                data: { item_form_target: "typeIcon" }
              ) do |s|
                s.circle(cx: "12", cy: "12", r: "10")
              end
            end

            # Submit button
            Button(type: :submit, variant: :ghost, icon: true, size: :sm, class: "shrink-0 h-9 w-9") do
              svg(
                xmlns: "http://www.w3.org/2000/svg",
                class: "h-4 w-4",
                viewBox: "0 0 24 24",
                fill: "none",
                stroke: "currentColor",
                stroke_width: "2"
              ) do |s|
                s.line(x1: "12", y1: "5", x2: "12", y2: "19")
                s.line(x1: "5", y1: "12", x2: "19", y2: "12")
              end
            end
          end
        end
      end

      def render_nested_items
        # Get descendant data if it exists
        descendant = @item.descendant
        active_item_ids = descendant&.extract_active_item_ids || []
        inactive_item_ids = descendant&.extract_inactive_item_ids || []
        all_item_ids = active_item_ids + inactive_item_ids
        has_items = all_item_ids.any?

        # Always render the container so Turbo can append to it
        div(class: "space-y-2") do
          # Section title - only show if there are items
          div(id: "nested_items_title_#{@item.id}") do
            if has_items
              div(class: "text-sm font-medium text-muted-foreground") { "Nested items" }
            end
          end

          # Items list - always render the container even if empty
          div(id: "nested_items_#{@item.id}", class: "space-y-2") do
            if has_items
              # Load all child items
              items = ::Item.where(id: all_item_ids).index_by(&:id)

              # Render active items first with move buttons
              active_item_ids.each_with_index do |item_id, index|
                item = items[item_id]
                next unless item
                render Views::Items::DrawerChildItem.new(
                  item: item,
                  parent_item: @item,
                  day: @day,
                  item_index: index,
                  total_items: active_item_ids.length
                )
              end

              # Render inactive items after (without move buttons)
              inactive_item_ids.each do |item_id|
                item = items[item_id]
                next unless item
                render Views::Items::Item.new(item: item, day: @day)
              end
            end
          end
        end
      end
    end
  end
end
