# frozen_string_literal: true

module Views
  module Items
    class ItemWithChildren < ::Views::Base
      def initialize(item:, day: nil, context: nil, depth: 0, public_view: false, is_editable: false)
        @item = item
        @day = day
        @list = context.is_a?(List) ? context : nil
        @depth = depth
        @public_view = public_view
        @is_editable = is_editable
      end

      def view_template
        # Wrap in a container div so we can replace the entire item+children structure
        div(id: "item_with_children_#{@item.id}") do
          # Render the item itself using proper component based on type
          case @item.item_type.to_sym
          when :section
            render ::Views::Items::SectionItem.new(
              record: @item,
              day: @day,
              list: @list,
              is_public_list: @public_view
            )
          else
            render ::Views::Items::CompletableItem.new(
              record: @item,
              day: @day,
              list: @list,
              is_public_list: @public_view
            )
          end

          # Render nested children if item has a descendant
          if @item.descendant
            render_children
          end
        end
      end

      private

      def render_children
        descendant = @item.descendant
        active_item_ids = descendant.extract_active_item_ids || []
        inactive_item_ids = descendant.extract_inactive_item_ids || []
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
            render ::Views::Items::ItemWithChildren.new(
              item: item,
              day: @day,
              context: @list,
              depth: @depth + 1,
              public_view: @public_view,
              is_editable: @is_editable
            )
          end

          # Render inactive items after (done, dropped, deferred)
          inactive_item_ids.each do |item_id|
            item = items[item_id]
            next unless item

            # Recursively render child with increased depth
            render ::Views::Items::ItemWithChildren.new(
              item: item,
              day: @day,
              context: @list,
              depth: @depth + 1,
              public_view: @public_view,
              is_editable: @is_editable
            )
          end
        end
      end
    end
  end
end
