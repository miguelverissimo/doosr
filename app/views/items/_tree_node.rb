# frozen_string_literal: true

module Views
  module Items
    class TreeNode < Views::Base
      def initialize(node:, day: nil, context: nil, public_view: false, is_editable: false)
        @node = node
        @day = day
        @list = context.is_a?(List) ? context : nil
        @public_view = public_view
        @is_editable = is_editable
      end

      def view_template
        return unless @node.item

        # Wrap in a container div
        div(id: "item_with_children_#{@node.item.id}") do
          # Render the item itself
          render Views::Items::Item.new(
            item: @node.item,
            day: @day,
            list: @list,
            is_public_list: @public_view
          )

          # Render children if any
          if @node.children.any?
            div(class: "ml-6 mt-2 space-y-2 border-l-2 border-border/50 pl-3") do
              @node.children.each do |child_node|
                render Views::Items::TreeNode.new(
                  node: child_node,
                  day: @day,
                  context: @list,
                  public_view: @public_view,
                  is_editable: @is_editable
                )
              end
            end
          end
        end
      end
    end
  end
end
