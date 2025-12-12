# frozen_string_literal: true

module Views
  module Lists
    class Show < Views::Base
      def initialize(list:, all_items: nil, active_items: nil, inactive_items: nil, item_titles: nil, is_owner: false)
        @list = list
        @all_items = all_items || []
        @active_items = active_items || []
        @inactive_items = inactive_items || []
        @item_titles = item_titles || []
        @is_owner = is_owner
      end

      def view_template
        div(
          class: "flex h-full flex-col",
          data: {
            controller: "list-subscription",
            list_subscription_list_id_value: @list.id
          }
        ) do
          # Header
          div(class: "flex items-center justify-between mb-6") do
            div(class: "flex items-center gap-4") do
              h1(class: "text-2xl font-bold") { @list.title }
              render_list_type_badge(@list)
            end

            div(class: "flex items-center gap-2") do
              if @list.list_type_public_list?
                Button(
                  href: public_list_path(@list.slug),
                  variant: :outline,
                  target: "_blank"
                ) do
                  plain "View Public"
                end
              end
              Button(href: edit_list_path(@list), variant: :outline) do
                plain "Edit"
              end
              Button(href: lists_path, variant: :outline) do
                plain "Back to Lists"
              end
            end
          end

          # Content
          div(class: "flex-1") do
            render_list_content
          end
        end
      end

      private

      def render_list_content
        div(class: "space-y-3") do
          # Error container for form errors
          div(id: "item_form_errors")

          # Add item form - only allow reusable and section types
          # Wrap in container for autocomplete positioning
          div(
            class: "relative",
            data: {
              controller: "item-autocomplete",
              item_autocomplete_titles_value: @item_titles.to_json,
              action: "item-form:itemAdded->item-autocomplete#addTitle list-subscription:listUpdated@window->item-autocomplete#refreshTitlesFromDOM"
            }
          ) do
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
              input(type: "hidden", name: "list_id", value: @list.id)
              input(
                type: "hidden",
                name: "item[item_type]",
                value: "reusable",
                data: { item_form_target: "itemType" }
              )

              Input(
                type: "text",
                name: "item[title]",
                placeholder: "Add an item...",
                class: "flex-1 text-sm h-9",
                data: {
                  item_form_target: "titleInput",
                  item_autocomplete_target: "input",
                  action: "input->item-autocomplete#search keydown->item-autocomplete#keydown"
                },
                required: true
              )

            # Type selector button (reusable by default for lists)
            Button(
              type: :button,
              variant: :ghost,
              icon: true,
              size: :sm,
              class: "shrink-0 h-9 w-9",
              data: { action: "click->item-form#cycleListType" }
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
                s.path(d: "M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z")
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

            # Autocomplete dropdown
            div(
              data: { item_autocomplete_target: "dropdown" },
              class: "hidden absolute z-50 mt-1 w-full max-h-60 overflow-auto rounded-md border bg-popover shadow-lg"
            ) do
              div(data: { item_autocomplete_target: "results" })
            end
          end

          # Root target for moving items (hidden by default) - BELOW input, ABOVE items
          div(
            data: { day_move_target: "rootTarget", action: "click->day-move#selectRootTarget" },
            class: "hidden rounded-lg border-2 border-dashed border-primary bg-primary/5 p-4 text-center cursor-pointer hover:bg-primary/10 transition-colors"
          ) do
            p(class: "text-sm font-medium") { "Drop here" }
          end

          # Items list
          div(id: "items_list", class: "space-y-2 mt-3") do
            # Render active items first
            @active_items.each do |item|
              render Views::Items::ItemWithChildren.new(item: item, context: @list)
            end

            # Render inactive items after (done, dropped, deferred)
            @inactive_items.each do |item|
              render Views::Items::ItemWithChildren.new(item: item, context: @list)
            end

            # Show empty state if no items
            if @active_items.empty? && @inactive_items.empty?
              div(class: "text-sm text-muted-foreground text-center py-8") do
                p { "No items in this list yet. Add your first item!" }
              end
            end
          end

          # Item actions sheet container (rendered dynamically via Turbo Stream)
          div(id: "item_actions_sheet")
        end
      end

      def render_list_type_badge(list)
        color_class = case list.list_type
        when "private_list"
          "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
        when "public_list"
          "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
        when "shared_list"
          "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300"
        end

        span(class: "px-2 py-1 text-xs font-medium rounded #{color_class}") do
          list.list_type.humanize
        end
      end
    end
  end
end
