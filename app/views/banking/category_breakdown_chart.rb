# frozen_string_literal: true

module Views
  module Banking
    class CategoryBreakdownChart < ::Views::Base
      def initialize(category_breakdown:, start_date:, end_date:, category_id: nil, breakdown_parent_id: nil)
        @category_breakdown = category_breakdown
        @start_date = start_date
        @end_date = end_date
        @category_id = category_id
        @breakdown_parent_id = breakdown_parent_id
      end

      def view_template
        div(
          class: "rounded-lg border bg-card p-6 shadow-sm relative",
          data: {
            controller: "category-chart",
            category_chart_data_value: chart_data.to_json,
            category_chart_filter_url_value: banking_index_path(start_date: @start_date, end_date: @end_date),
            category_chart_drilldown_mode_value: @breakdown_parent_id.present?.to_s
          }
        ) do
          render_loading_overlay
          render_header
          render_chart_or_empty
        end
      end

      private

      def render_loading_overlay
        div(
          class: "absolute inset-0 bg-card/80 backdrop-blur-sm z-10 hidden flex items-center justify-center rounded-lg",
          data: { category_chart_target: "loading" }
        ) do
          render ::Components::Shared::LoadingSpinner.new(message: "Loading...")
        end
      end

      def render_header
        div(class: "flex items-center justify-between mb-4") do
          div(class: "flex items-center gap-2") do
            render ::Components::Icon::PieChart.new(size: "20", class: "text-muted-foreground")
            h3(class: "text-lg font-semibold") { header_title }
          end
          render_back_button if @breakdown_parent_id.present?
        end
      end

      def header_title
        if @breakdown_parent_id.present?
          parent_item = @category_breakdown.find { |item| item[:is_parent] }
          parent_name = parent_item&.dig(:name) || "Category"
          "#{parent_name} Breakdown"
        else
          "Spending by Category"
        end
      end

      def render_back_button
        a(
          href: back_to_all_categories_path,
          class: "inline-flex items-center text-sm text-muted-foreground hover:text-foreground transition-colors",
          data: { turbo_stream: false, action: "click->category-chart#showLoading" }
        ) do
          render ::Components::Icon::ArrowLeft.new(size: "16", class: "mr-1")
          plain "All Categories"
        end
      end

      def back_to_all_categories_path
        params = { start_date: @start_date, end_date: @end_date }
        params[:category_id] = @category_id if @category_id.present?
        banking_index_path(params)
      end

      def render_chart_or_empty
        if @category_breakdown.empty?
          render_empty_state
        else
          render_chart_with_legend
        end
      end

      def render_empty_state
        div(class: "flex flex-col items-center justify-center py-12 text-muted-foreground") do
          render ::Components::Icon::PieChart.new(size: "48", class: "mb-4 opacity-50")
          p(class: "text-sm") { "No expense data for this period" }
        end
      end

      def render_chart_with_legend
        div(class: "flex flex-col lg:flex-row gap-6") do
          render_chart
          render_legend
        end
      end

      def render_chart
        div(class: "flex-shrink-0 w-full lg:w-64 h-64") do
          canvas(data: { category_chart_target: "canvas" })
        end
      end

      def render_legend
        div(class: "flex-1 min-w-0") do
          div(class: "grid gap-2 max-h-64 overflow-y-auto") do
            sorted_breakdown.each do |item|
              render_legend_item(item)
            end
          end
        end
      end

      def render_legend_item(item)
        has_subcategories = item[:has_subcategories] || false
        is_active = @category_id.present? && (
          (@category_id == "uncategorized" && item[:id] == "uncategorized") ||
          (@category_id.to_s == item[:id].to_s)
        )
        is_drilldown_mode = @breakdown_parent_id.present?

        # Determine what happens when clicking
        if has_subcategories && !is_drilldown_mode
          # Drill down into subcategories
          href = drill_down_path(item[:id])
          clickable = true
        elsif !is_drilldown_mode
          # Filter by this category
          href = category_filter_path(item[:id])
          clickable = true
        else
          # In drill-down mode, clicking filters by subcategory
          href = category_filter_path(item[:id])
          clickable = true
        end

        wrapper_class = "flex items-center justify-between p-2 rounded-md transition-colors group"
        wrapper_class += clickable ? " hover:bg-muted/50 cursor-pointer" : ""
        wrapper_class += is_active ? " bg-muted" : ""

        a(
          href: href,
          class: wrapper_class,
          data: clickable ? { turbo_stream: false, action: "click->category-chart#showLoading" } : {}
        ) do
          div(class: "flex items-center gap-3 min-w-0") do
            div(
              class: "w-3 h-3 rounded-full flex-shrink-0",
              style: "background-color: #{item[:color]}"
            )
            span(class: "text-sm truncate") { item[:name] }
            if has_subcategories && !is_drilldown_mode
              render ::Components::Icon::ChevronRight.new(size: "14", class: "text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity")
            end
          end
          div(class: "flex items-center gap-2 flex-shrink-0") do
            span(class: "text-sm font-medium") { format_currency(item[:amount].abs) }
            span(class: "text-xs text-muted-foreground") { "(#{item[:percentage]}%)" }
          end
        end
      end

      def drill_down_path(category_id)
        params = { start_date: @start_date, end_date: @end_date, breakdown_parent_id: category_id }
        banking_index_path(params)
      end

      def category_filter_path(category_id)
        params = { start_date: @start_date, end_date: @end_date }
        if category_id == "uncategorized"
          params[:category_id] = "uncategorized"
        elsif category_id
          params[:category_id] = category_id
        end
        banking_index_path(params)
      end

      def chart_data
        sorted_breakdown.map do |item|
          {
            id: item[:id],
            name: item[:name],
            amount: item[:amount].abs,
            color: item[:color],
            has_subcategories: item[:has_subcategories] || false
          }
        end
      end

      def sorted_breakdown
        @sorted_breakdown ||= @category_breakdown.sort_by { |item| -item[:amount].abs }
      end

      def format_currency(amount)
        "€#{number_with_delimiter(sprintf('%.2f', amount))}"
      end
    end
  end
end
