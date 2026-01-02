# frozen_string_literal: true

module Views
  module Lists
    class Show < ::Views::Base
      def initialize(list:, tree: nil, item_titles: nil, is_owner: false)
        @list = list
        @tree = tree
        @item_titles = item_titles || []
        @is_owner = is_owner
      end

      def view_template
        div(
          class: "flex h-full flex-col",
          data: {
            controller: "list-subscription list-loader day-move",
            list_subscription_list_id_value: @list.id,
            day_move_list_id_value: @list.id
          }
        ) do
          # Cancel button for moving mode (hidden by default)
          div(
            data: { day_move_target: "cancelButton" },
            class: "hidden mb-3"
          ) do
            Button(variant: :outline, size: :sm, data: { action: "click->day-move#cancelMoving" }) do
              "Cancel Move"
            end
          end
          # Loading spinner (shown on page load, hidden by controller)
          div(
            data: { list_loader_target: "spinner" },
            class: "flex items-center justify-center py-12"
          ) do
            render ::Components::Shared::LoadingSpinner.new(message: "Loading list...")
          end

          # Content (hidden initially, shown by controller)
          div(
            data: { list_loader_target: "content" },
            class: "hidden"
          ) do
            render_full_content
          end
        end
      end

      private

      def render_full_content
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

      def render_list_content
        div(class: "space-y-3") do
          # Error container for form errors
          div(id: "item_form_errors")

          # Add item form
          render ::Views::Lists::ActionsRow.new(list: @list, item_titles: @item_titles)

          # Root target for moving items (hidden by default) - BELOW input, ABOVE items
          div(
            data: { day_move_target: "rootTarget", action: "click->day-move#selectRootTarget" },
            class: "hidden rounded-lg border-2 border-dashed border-primary bg-primary/5 p-4 text-center cursor-pointer hover:bg-primary/10 transition-colors"
          ) do
            p(class: "text-sm font-medium") { "Drop here" }
          end

          # Items list
          div(id: "items_list", class: "space-y-2 mt-3") do
            # Render tree nodes from the pre-built tree
            if @tree && @tree.children.any?
              @tree.children.each do |node|
                render ::Views::Items::TreeNode.new(node: node, context: @list)
              end
            else
              # Show empty state if no items
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
