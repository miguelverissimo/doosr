# frozen_string_literal: true

module Views
  module Lists
    class Index < Views::Base
      def initialize(lists:)
        @lists = lists
      end

      def view_template
        div(class: "flex h-full flex-col") do
          # Header
          div(class: "flex items-center justify-between mb-6") do
            h1(class: "text-2xl font-bold") { "Lists" }
            Button(href: new_list_path, variant: :default) do
              plain "New List"
            end
          end

          # Lists grid
          if @lists.any?
            div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4") do
              @lists.each do |list|
                render_list_card(list)
              end
            end
          else
            div(class: "text-sm text-muted-foreground text-center py-8") do
              p { "No lists yet. Create your first list!" }
            end
          end
        end
      end

      private

      def render_list_card(list)
        a(
          href: list_path(list),
          class: "block p-6 bg-card border rounded-lg hover:shadow-md transition-shadow"
        ) do
          div(class: "flex items-start justify-between mb-2") do
            h2(class: "text-lg font-semibold") { list.title }
            render_list_type_badge(list)
          end

          div(class: "text-sm text-muted-foreground") do
            if list.descendant
              item_count = list.descendant.extract_active_item_ids.length
              plain "#{item_count} item#{item_count == 1 ? '' : 's'}"
            else
              plain "0 items"
            end
          end

          if list.list_type_public_list?
            div(class: "mt-4 pt-4 border-t") do
              p(class: "text-xs text-muted-foreground truncate") do
                plain "Public URL: #{list.public_url}"
              end
            end
          end
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
