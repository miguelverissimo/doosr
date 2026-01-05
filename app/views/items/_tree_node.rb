# frozen_string_literal: true

module Views
  module Items
    class TreeNode < ::Views::Base
      def initialize(node:, day: nil, context: nil, public_view: false, is_editable: false)
        @node = node
        @day = day
        @list = context.is_a?(List) ? context : nil
        @public_view = public_view
        @is_editable = is_editable
      end

      def view_template
        record = @node.item || @node.list || @node.checklist
        return unless record

        # Wrap in a container div
        div(id: "#{record.class.name.downcase}_with_children_#{record.id}") do
          # Route to appropriate component based on type
          if @node.item
            render_item_component(@node.item)
          elsif @node.list
            render ::Views::Items::ListLinkItem.new(
              record: @node.list,
              day: @day,
              list: @list,
              is_public_list: @public_view
            )
          elsif @node.checklist
            render ::Views::Items::ChecklistLinkItem.new(
              record: @node.checklist,
              day: @day,
              list: @list,
              is_public_list: @public_view
            )
          end

          # Render children (only for items, not lists/checklists in day context)
          if @node.children.any? && @node.item
            div(class: "ml-6 mt-2 space-y-2 border-l-2 border-border/50 pl-3") do
              @node.children.each do |child_node|
                render ::Views::Items::TreeNode.new(
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

      private

      def render_item_component(item)
        case item.item_type.to_sym
        when :completable, :reusable, :trackable
          render ::Views::Items::CompletableItem.new(
            record: item,
            day: @day,
            list: @list,
            is_public_list: @public_view
          )
        when :section
          render ::Views::Items::SectionItem.new(
            record: item,
            day: @day,
            list: @list,
            is_public_list: @public_view
          )
        else
          # Fallback - should not happen but use CompletableItem as safe default
          render ::Views::Items::CompletableItem.new(
            record: item,
            day: @day,
            list: @list,
            is_public_list: @public_view
          )
        end
      end
    end
  end
end
