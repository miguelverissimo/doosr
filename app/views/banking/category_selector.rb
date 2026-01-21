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
          class: "relative inline-flex flex-wrap gap-1 items-center",
          data: {
            controller: "category-selector",
            category_selector_url_value: view_context.update_category_banking_path(@transaction),
            category_selector_edit_url_value: view_context.edit_categories_banking_path(@transaction)
          }
        ) do
          render_category_badges
          render_category_dropdown
          render_success_indicator if @show_success
        end
      end

      private

      def render_category_badges
        # Use the already preloaded association - don't trigger new queries
        categorizations = @transaction.transaction_categorizations

        if categorizations.size > 0
          categorizations.each do |tc|
            render_categorization_badge(tc)
          end
          render_edit_button
        else
          render_uncategorized_badge
        end
      end

      def render_categorization_badge(tc)
        category = tc.category
        has_amount = tc.amount.present?

        span(
          class: "inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ring-1 ring-inset",
          style: "background-color: #{category.effective_color}20; color: #{category.effective_color}; ring-color: #{category.effective_color}40;"
        ) do
          plain category.name
          if has_amount
            span(class: "ml-1 opacity-75") { " €#{sprintf('%.2f', tc.amount)}" }
          end
        end
      end

      def render_uncategorized_badge
        span(
          class: "text-muted-foreground text-xs cursor-pointer hover:opacity-80 transition-opacity",
          data: { category_selector_target: "badge" }
        ) { "Uncategorized" }
      end

      def render_edit_button
        button(
          type: "button",
          class: "inline-flex items-center justify-center h-6 w-6 rounded-full text-muted-foreground hover:bg-muted hover:text-foreground transition-colors",
          title: "Edit categories",
          data: {
            action: "click->category-selector#openEditDialog"
          }
        ) do
          render ::Components::Icon::Edit.new(size: "12")
        end
      end

      def render_category_dropdown
        # Simple dropdown for quick single-category selection (when uncategorized)
        select(
          class: "absolute inset-0 opacity-0 cursor-pointer w-full h-full",
          data: {
            category_selector_target: "select",
            action: "change->category-selector#change"
          }
        ) do
          option(value: "", selected: @transaction.transaction_categorizations.size == 0) { "None" }
          render_hierarchical_options
        end
      end

      def render_hierarchical_options
        @categories.each do |category|
          # Use .size on preloaded association to avoid queries
          if category.subcategories.size > 0
            optgroup(label: category.name) do
              option(value: category.id) { category.name }
              # Sort in Ruby to avoid query - subcategories already preloaded
              category.subcategories.sort_by(&:name).each do |sub|
                option(value: sub.id) { "  └ #{sub.name}" }
              end
            end
          else
            option(value: category.id) { category.name }
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
