# frozen_string_literal: true

module Views
  module Items
    class SectionItem < BaseItem
      def item_classes
        "flex w-full cursor-pointer items-center gap-2 rounded-md bg-muted p-3 text-left transition-colors hover:bg-muted/85"
      end

      def render_icon
        div(class: "flex h-3.5 w-3.5 items-center justify-center shrink-0") do
          render ::Components::Icon.new(name: :hash, size: "14", class: "text-muted-foreground")
        end
      end

      def render_content
        div(class: "flex-1 min-w-0") do
          h3(class: "font-semibold text-sm truncate") { @record.title }
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
    end
  end
end
