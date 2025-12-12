# frozen_string_literal: true

module Views
  module Lists
    class PublicShow < Views::Base
      def initialize(list:, all_items: nil, active_items: nil, inactive_items: nil, item_titles: nil, is_owner: false, is_editable: false)
        @list = list
        @all_items = all_items || []
        @active_items = active_items || []
        @inactive_items = inactive_items || []
        @item_titles = item_titles || []
        @is_owner = is_owner
        @is_editable = is_editable
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
              # Theme toggle
              ThemeToggle do |toggle|
                toggle.SetLightMode do
                  Button(variant: :outline, icon: true, size: :sm) do
                    svg(
                      xmlns: "http://www.w3.org/2000/svg",
                      viewbox: "0 0 24 24",
                      fill: "currentColor",
                      class: "w-4 h-4"
                    ) do |s|
                      s.path(
                        d: "M12 2.25a.75.75 0 01.75.75v2.25a.75.75 0 01-1.5 0V3a.75.75 0 01.75-.75zM7.5 12a4.5 4.5 0 119 0 4.5 4.5 0 01-9 0zM18.894 6.166a.75.75 0 00-1.06-1.06l-1.591 1.59a.75.75 0 101.06 1.061l1.591-1.59zM21.75 12a.75.75 0 01-.75.75h-2.25a.75.75 0 010-1.5H21a.75.75 0 01.75.75zM17.834 18.894a.75.75 0 001.06-1.06l-1.59-1.591a.75.75 0 10-1.061 1.06l1.59 1.591zM12 18a.75.75 0 01.75.75V21a.75.75 0 01-1.5 0v-2.25A.75.75 0 0112 18zM7.758 17.303a.75.75 0 00-1.061-1.06l-1.591 1.59a.75.75 0 001.06 1.061l1.591-1.59zM6 12a.75.75 0 01-.75.75H3a.75.75 0 010-1.5h2.25A.75.75 0 016 12zM6.697 7.757a.75.75 0 001.06-1.06l-1.59-1.591a.75.75 0 00-1.061 1.06l1.59 1.591z"
                      )
                    end
                  end
                end

                toggle.SetDarkMode do
                  Button(variant: :outline, icon: true, size: :sm) do
                    svg(
                      xmlns: "http://www.w3.org/2000/svg",
                      viewbox: "0 0 24 24",
                      fill: "currentColor",
                      class: "w-4 h-4"
                    ) do |s|
                      s.path(
                        fill_rule: "evenodd",
                        d: "M9.528 1.718a.75.75 0 01.162.819A8.97 8.97 0 009 6a9 9 0 009 9 8.97 8.97 0 003.463-.69.75.75 0 01.981.98 10.503 10.503 0 01-9.694 6.46c-5.799 0-10.5-4.701-10.5-10.5 0-4.368 2.667-8.112 6.46-9.694a.75.75 0 01.818.162z",
                        clip_rule: "evenodd"
                      )
                    end
                  end
                end
              end

              h1(class: "text-2xl font-bold") { @list.title }
              render_visibility_badge
            end

            if @is_owner
              div(class: "flex items-center gap-2") do
                Button(href: list_path(@list), variant: :outline) do
                  plain "Owner View"
                end
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

          # Add item form - only show if editable
          if @is_editable
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
          else
            # Read-only message
            div(class: "bg-muted p-3 rounded-lg text-sm text-muted-foreground") do
              plain "This is a read-only public list. You can view but not modify items."
            end
          end

          # Root target for moving items (hidden by default) - BELOW input, ABOVE items
          if @is_editable
            div(
              data: { day_move_target: "rootTarget", action: "click->day-move#selectRootTarget" },
              class: "hidden rounded-lg border-2 border-dashed border-primary bg-primary/5 p-4 text-center cursor-pointer hover:bg-primary/10 transition-colors"
            ) do
              p(class: "text-sm font-medium") { "Drop here" }
            end
          end

          # Items list
          div(id: "items_list", class: "space-y-2 mt-3") do
            # Render active items first
            @active_items.each do |item|
              render Views::Items::ItemWithChildren.new(
                item: item,
                context: @list,
                public_view: true,
                is_editable: @is_editable
              )
            end

            # Render inactive items after (done, dropped, deferred)
            @inactive_items.each do |item|
              render Views::Items::ItemWithChildren.new(
                item: item,
                context: @list,
                public_view: true,
                is_editable: @is_editable
              )
            end

            # Show empty state if no items
            if @active_items.empty? && @inactive_items.empty?
              div(class: "text-sm text-muted-foreground text-center py-8") do
                p { "This list is empty." }
              end
            end
          end

          # Item actions sheet container (rendered dynamically via Turbo Stream)
          div(id: "item_actions_sheet")
        end
      end

      def render_visibility_badge
        color_class = if @is_editable
          "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
        else
          "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300"
        end

        span(class: "px-2 py-1 text-xs font-medium rounded #{color_class}") do
          @is_editable ? "Editable" : "Read Only"
        end
      end
    end
  end
end
