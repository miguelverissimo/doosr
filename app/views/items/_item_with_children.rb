# frozen_string_literal: true

module Views
  module Items
    class ItemWithChildren < Views::Base
      def initialize(item:, day: nil, depth: 0)
        @item = item
        @day = day
        @depth = depth
      end

      def view_template
        # Render the item itself
        render Views::Items::Item.new(item: @item, day: @day)

        # Render nested children if item has a descendant
        if @item.descendant
          render_children
        end
      end

      private

      def render_children
        descendant = @item.descendant
        item_ids = descendant.active_items
        return if item_ids.empty?

        # Load all child items with their descendants (use :: to reference top-level Item model)
        items = ::Item.includes(:descendant).where(id: item_ids).index_by(&:id)

        # Render children in a nested container with left margin
        div(class: "ml-6 mt-2 space-y-2 border-l-2 border-border/50 pl-3") do
          item_ids.each do |item_id|
            item = items[item_id]
            next unless item

            # Recursively render child with increased depth
            render Views::Items::ItemWithChildren.new(
              item: item,
              day: @day,
              depth: @depth + 1
            )
          end
        end
      end
    end
  end
end
