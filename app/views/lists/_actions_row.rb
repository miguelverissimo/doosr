module Views
  module Lists
    class ActionsRow < ::Views::Base
      def initialize(list:, item_titles: [])
        @list = list
        @item_titles = item_titles
      end

      def view_template
        div(class: "space-y-2") do
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
              action: reusable_items_path,
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
        end
      end
    end
  end
end
