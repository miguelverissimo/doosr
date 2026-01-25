# frozen_string_literal: true

module Views
  module Banking
    module Forecasts
      class ProjectionsChart < ::Views::Base
        def initialize(projections:, current_balance:)
          @projections = projections
          @current_balance = current_balance
        end

        def view_template
          div(
            class: "rounded-lg border bg-card p-6 shadow-sm",
            data: {
              controller: "forecast-chart",
              forecast_chart_projections_value: chart_data.to_json
            }
          ) do
            render_header
            render_chart_container
            render_legend
          end
        end

        private

        def render_header
          div(class: "flex items-center justify-between mb-4") do
            div do
              h3(class: "text-lg font-semibold") { "Balance Projection" }
              p(class: "text-sm text-muted-foreground") { "Weekly balance forecast for the next 12 weeks" }
            end
            render_projection_summary
          end
        end

        def render_projection_summary
          final_balance = @projections.last&.ending_balance || @current_balance
          change = final_balance - @current_balance
          is_positive = change >= 0

          div(class: "text-right") do
            div(class: "text-sm text-muted-foreground") { "Projected end balance" }
            div(class: "text-xl font-bold #{is_positive ? 'text-green-600' : 'text-red-600'}") do
              plain format_currency(final_balance)
            end
            div(class: "text-xs #{is_positive ? 'text-green-600' : 'text-red-600'}") do
              plain "#{is_positive ? '+' : ''}#{format_currency(change)}"
            end
          end
        end

        def render_chart_container
          div(
            id: "forecast_chart",
            class: "h-64",
            data: { forecast_chart_target: "chart" }
          ) do
            render_fallback_chart
          end
        end

        def render_fallback_chart
          min_balance = @projections.map(&:ending_balance).min
          max_balance = [ @current_balance, @projections.map(&:ending_balance).max ].max
          range = max_balance - min_balance
          range = 1 if range.zero?

          div(class: "flex gap-1 h-full pb-5") do
            @projections.each_with_index do |projection, index|
              height_pct = ((projection.ending_balance - min_balance) / range * 100).clamp(5, 100)
              is_negative = projection.ending_balance < 0

              div(class: "flex-1 h-full relative") do
                div(
                  class: "absolute bottom-0 left-0 right-0 rounded-t #{is_negative ? 'bg-red-500' : 'bg-primary'}",
                  style: "height: #{height_pct}%",
                  title: "Week #{index + 1}: #{format_currency(projection.ending_balance)}"
                )
                div(class: "absolute -bottom-5 left-0 right-0 text-center text-[10px] text-muted-foreground") do
                  plain projection.week_start.strftime("%m/%d")
                end
              end
            end
          end
        end

        def render_legend
          div(class: "flex flex-wrap gap-4 mt-4 pt-4 border-t text-sm") do
            render_legend_item("Balance", "bg-primary")
            if @projections.any? { |p| p.ending_balance < 0 }
              render_legend_item("Negative", "bg-red-500")
            end
          end
        end

        def render_legend_item(label, color_class)
          div(class: "flex items-center gap-2") do
            div(class: "w-3 h-3 rounded #{color_class}")
            span(class: "text-muted-foreground") { label }
          end
        end

        def chart_data
          @projections.map do |p|
            {
              week: p.week_start.strftime("%b %d"),
              balance: p.ending_balance.round(2),
              income: p.recurring_income.round(2),
              expenses: (p.recurring_expenses + p.planned_expenses + p.variable_spending).round(2)
            }
          end
        end

        def format_currency(amount)
          "#{view_context.number_with_delimiter(sprintf('%.2f', amount))}"
        end
      end
    end
  end
end
