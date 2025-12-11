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
        # Wrap in a container div so we can replace the entire item+children structure
        div(id: "item_with_children_#{@item.id}") do
          # Render the item itself
          render Views::Items::Item.new(item: @item, day: @day)

          # Render nested children if item has a descendant
          if @item.descendant
            render_children
          end
        end
      end

      private

      def render_children
        descendant = @item.descendant
        active_item_ids = descendant.active_items || []
        inactive_item_ids = descendant.inactive_items || []
        all_item_ids = active_item_ids + inactive_item_ids

        return if all_item_ids.empty?

        # Load all child items with their descendants (use :: to reference top-level Item model)
        items = ::Item.includes(:descendant).where(id: all_item_ids).index_by(&:id)

        # Render children in a nested container with left margin
        div(class: "ml-6 mt-2 space-y-2 border-l-2 border-border/50 pl-3") do
          # Render active items first
          active_item_ids.each do |item_id|
            item = items[item_id]
            next unless item

            # Recursively render child with increased depth
            render Views::Items::ItemWithChildren.new(
              item: item,
              day: @day,
              depth: @depth + 1
            )
          end

          # Render inactive items after (done, dropped, deferred)
          inactive_item_ids.each do |item_id|
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
