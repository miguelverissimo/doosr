# frozen_string_literal: true

module Views
  module Banking
    module Forecasts
      class WarningsPanel < ::Views::Base
        def initialize(warnings:)
          @warnings = warnings
        end

        def view_template
          div(class: "rounded-lg border bg-card shadow-sm") do
            render_header
            render_warnings_list
          end
        end

        private

        def render_header
          div(class: "flex items-center gap-2 p-4 border-b bg-amber-50 dark:bg-amber-950 rounded-t-lg") do
            render ::Components::Icon::AlertTriangle.new(size: "20", class: "text-amber-500")
            h3(class: "font-semibold text-amber-700 dark:text-amber-300") { "Warnings" }
            Badge(variant: :warning, class: "ml-auto") { @warnings.size.to_s }
          end
        end

        def render_warnings_list
          div(class: "divide-y") do
            @warnings.each do |warning|
              render_warning_item(warning)
            end
          end
        end

        def render_warning_item(warning)
          div(class: "p-4 hover:bg-muted/50") do
            div(class: "flex items-start gap-3") do
              render_warning_icon(warning.type)
              div(class: "flex-1") do
                p(class: "font-medium") { warning.message }
                div(class: "flex items-center gap-2 mt-1 text-sm text-muted-foreground") do
                  render ::Components::Icon::Calendar.new(size: "14")
                  span { "Week of #{warning.week.strftime('%b %d, %Y')}" }
                end
              end
            end
          end
        end

        def render_warning_icon(type)
          case type
          when :shortfall
            div(class: "p-2 rounded-full bg-red-100 dark:bg-red-900") do
              render ::Components::Icon::AlertTriangle.new(size: "16", class: "text-red-500")
            end
          when :low_balance
            div(class: "p-2 rounded-full bg-amber-100 dark:bg-amber-900") do
              render ::Components::Icon::AlertTriangle.new(size: "16", class: "text-amber-500")
            end
          else
            div(class: "p-2 rounded-full bg-muted") do
              render ::Components::Icon::AlertTriangle.new(size: "16", class: "text-muted-foreground")
            end
          end
        end
      end
    end
  end
end
