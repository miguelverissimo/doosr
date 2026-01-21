# frozen_string_literal: true

module Views
  module Banking
    module Forecasts
      class SuggestionsPanel < ::Views::Base
        def initialize(suggestions:)
          @suggestions = suggestions
        end

        def view_template
          div(class: "rounded-lg border bg-card shadow-sm") do
            render_header
            render_suggestions_list
            render_total_savings
          end
        end

        private

        def render_header
          div(class: "flex items-center gap-2 p-4 border-b bg-blue-50 dark:bg-blue-950 rounded-t-lg") do
            render ::Components::Icon::Lightbulb.new(size: "20", class: "text-blue-500")
            h3(class: "font-semibold text-blue-700 dark:text-blue-300") { "Suggestions" }
            Badge(variant: :info, class: "ml-auto") { @suggestions.size.to_s }
          end
        end

        def render_suggestions_list
          div(class: "divide-y") do
            @suggestions.each do |suggestion|
              render_suggestion_item(suggestion)
            end
          end
        end

        def render_suggestion_item(suggestion)
          category = suggestion[:category]

          div(class: "p-4 hover:bg-muted/50") do
            div(class: "flex items-start gap-3") do
              div(
                class: "w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0",
                style: "background-color: #{category.color}20"
              ) do
                div(
                  class: "w-4 h-4 rounded-full",
                  style: "background-color: #{category.color}"
                )
              end

              div(class: "flex-1") do
                p(class: "font-medium") { category.name }
                p(class: "text-sm text-muted-foreground mt-1") do
                  plain "Reduce from "
                  span(class: "font-medium") { format_currency(suggestion[:current_average]) }
                  plain " to "
                  span(class: "font-medium text-green-600") { format_currency(suggestion[:suggested_limit]) }
                  plain " per month"
                end
                div(class: "flex items-center gap-2 mt-2") do
                  Badge(variant: :success) { "Save #{format_currency(suggestion[:reduction_amount])}/mo" }
                  span(class: "text-xs text-muted-foreground") do
                    plain "High variability (CV: #{(suggestion[:coefficient_of_variation] * 100).round}%)"
                  end
                end
              end
            end
          end
        end

        def render_total_savings
          total = @suggestions.sum { |s| s[:reduction_amount] }

          div(class: "p-4 bg-green-50 dark:bg-green-950 border-t rounded-b-lg") do
            div(class: "flex items-center justify-between") do
              span(class: "font-medium text-green-700 dark:text-green-300") { "Total potential savings" }
              span(class: "text-xl font-bold text-green-600") { "#{format_currency(total)}/mo" }
            end
          end
        end

        def format_currency(amount)
          "#{view_context.number_with_delimiter(sprintf('%.2f', amount))}"
        end
      end
    end
  end
end
