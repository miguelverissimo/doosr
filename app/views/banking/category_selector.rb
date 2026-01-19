# frozen_string_literal: true

module Views
  module Banking
    class CategorySelector < ::Views::Base
      def initialize(transaction:, categories:, show_success: false)
        @transaction = transaction
        @categories = categories
        @show_success = show_success
      end

      def view_template
        div(
          id: "transaction_#{@transaction.id}_category",
          class: "relative inline-block",
          data: {
            controller: "category-selector",
            category_selector_url_value: view_context.update_category_banking_path(@transaction)
          }
        ) do
          render_category_badge(@transaction.category)
          render_category_dropdown
          render_success_indicator if @show_success
        end
      end

      private

      def render_category_badge(category)
        if category
          span(
            class: "inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ring-1 ring-inset cursor-pointer hover:opacity-80 transition-opacity",
            style: "background-color: #{category.color}20; color: #{category.color}; ring-color: #{category.color}40;",
            data: { category_selector_target: "badge" }
          ) { category.name }
        else
          span(
            class: "text-muted-foreground text-xs cursor-pointer hover:opacity-80 transition-opacity",
            data: { category_selector_target: "badge" }
          ) { "Uncategorized" }
        end
      end

      def render_category_dropdown
        select(
          class: "absolute inset-0 opacity-0 cursor-pointer w-full h-full",
          data: {
            category_selector_target: "select",
            action: "change->category-selector#change"
          }
        ) do
          option(value: "", selected: @transaction.category_id.nil?) { "None" }
          @categories.each do |category|
            option(
              value: category.id,
              selected: @transaction.category_id == category.id
            ) { category.name }
          end
        end
      end

      def render_success_indicator
        span(
          class: "absolute -top-1 -right-1 flex h-3 w-3 animate-ping rounded-full bg-green-400 opacity-75",
          data: { controller: "auto-hide", auto_hide_delay_value: "1000" }
        )
      end
    end
  end
end
