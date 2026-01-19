# frozen_string_literal: true

module Views
  module Banking
    class SpendingOverTimeChart < ::Views::Base
      def initialize(time_series_data:, start_date:, end_date:, granularity:)
        @time_series_data = time_series_data
        @start_date = start_date
        @end_date = end_date
        @granularity = granularity
      end

      def view_template
        div(
          class: "rounded-lg border bg-card p-6 shadow-sm",
          data: {
            controller: "spending-chart",
            spending_chart_data_value: chart_data.to_json
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
            render ::Components::Icon::BarChart.new(size: "20", class: "text-muted-foreground")
            h3(class: "text-lg font-semibold") { "Spending Over Time" }
          end
          div(class: "text-sm text-muted-foreground") do
            plain granularity_label
          end
        end
      end

      def render_chart_or_empty
        if @time_series_data.empty?
          render_empty_state
        else
          render_chart
        end
      end

      def render_empty_state
        div(class: "flex flex-col items-center justify-center py-12 text-muted-foreground") do
          render ::Components::Icon::BarChart.new(size: "48", class: "mb-4 opacity-50")
          p(class: "text-sm") { "No transaction data for this period" }
        end
      end

      def render_chart
        div(class: "h-64") do
          canvas(data: { spending_chart_target: "canvas" })
        end
      end

      def chart_data
        {
          labels: @time_series_data.map { |d| d[:label] },
          income: @time_series_data.map { |d| d[:income] },
          expenses: @time_series_data.map { |d| d[:expenses] }
        }
      end

      def granularity_label
        case @granularity
        when :daily
          "Daily totals"
        when :weekly
          "Weekly totals"
        when :monthly
          "Monthly totals"
        else
          "Totals"
        end
      end
    end
  end
end
