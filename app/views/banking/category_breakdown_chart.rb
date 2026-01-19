# frozen_string_literal: true

module Views
  module Banking
    class CategoryBreakdownChart < ::Views::Base
      def initialize(category_breakdown:, start_date:, end_date:, category_id: nil)
        @category_breakdown = category_breakdown
        @start_date = start_date
        @end_date = end_date
        @category_id = category_id
      end

      def view_template
        div(
          class: "rounded-lg border bg-card p-6 shadow-sm",
          data: {
            controller: "category-chart",
            category_chart_data_value: chart_data.to_json,
            category_chart_filter_url_value: banking_index_path(start_date: @start_date, end_date: @end_date)
          }
        ) do
          render_header
          render_chart_or_empty
        end
      end

      private

      def render_header
        div(class: "flex items-center justify-between mb-4") do
          div(class: "flex items-center gap-2") do
            render ::Components::Icon::PieChart.new(size: "20", class: "text-muted-foreground")
            h3(class: "text-lg font-semibold") { "Spending by Category" }
          end
        end
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
        is_active = @category_id.present? && (
          (@category_id == "uncategorized" && item[:id] == "uncategorized") ||
          (@category_id.to_s == item[:id].to_s)
        )

        a(
          href: category_filter_path(item[:id]),
          class: "flex items-center justify-between p-2 rounded-md hover:bg-muted/50 transition-colors group #{is_active ? 'bg-muted' : ''}",
          data: { turbo_stream: true }
        ) do
          div(class: "flex items-center gap-3 min-w-0") do
            div(
              class: "w-3 h-3 rounded-full flex-shrink-0",
              style: "background-color: #{item[:color]}"
            )
            span(class: "text-sm truncate") { item[:name] }
          end
          div(class: "flex items-center gap-2 flex-shrink-0") do
            span(class: "text-sm font-medium") { format_currency(item[:amount].abs) }
            span(class: "text-xs text-muted-foreground") { "(#{item[:percentage]}%)" }
          end
        end
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
            color: item[:color]
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
