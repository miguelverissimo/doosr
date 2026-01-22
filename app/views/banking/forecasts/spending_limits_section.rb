# frozen_string_literal: true

module Views
  module Banking
    module Forecasts
      class SpendingLimitsSection < ::Views::Base
        def initialize(section_spending:)
          @section_spending = section_spending
        end

        def view_template
          div(class: "rounded-lg border bg-card shadow-sm") do
            render_header
            render_content
          end
        end

        private

        def render_header
          div(class: "flex items-center justify-between p-4 border-b") do
            div(class: "flex items-center gap-3") do
              render ::Components::Icon::Target.new(size: "20", class: "text-muted-foreground")
              h2(class: "font-semibold") { "Spending Limits" }
              span(class: "text-sm text-muted-foreground") { "This Month" }
            end
            button(
              type: "button",
              class: "text-sm text-muted-foreground hover:text-foreground",
              data: {
                controller: "enable-dialog",
                enable_dialog_url_value: view_context.banking_budget_goals_path,
                action: "click->enable-dialog#openDialog"
              }
            ) { "Manage" }
          end
        end

        def render_content
          if @section_spending.empty?
            render_empty_state
          else
            div(class: "divide-y max-h-96 overflow-y-auto") do
              @section_spending.each do |spending|
                render_section_item(spending)
              end
            end
          end
        end

        def render_empty_state
          div(class: "p-8 text-center") do
            p(class: "text-sm text-muted-foreground") do
              plain "No spending limits set. Set limits for sections to track your spending."
            end
          end
        end

        def render_section_item(spending)
          section = spending.section
          has_limit = spending.limit > 0
          progress_color = if spending.over_limit
            "bg-red-500"
          elsif spending.progress_percentage >= 80
            "bg-amber-500"
          else
            "bg-primary"
          end

          div(class: "p-4 hover:bg-muted/50") do
            div(class: "space-y-3") do
              # Section header
              div(class: "flex items-center justify-between") do
                div(class: "flex items-center gap-2 min-w-0") do
                  div(
                    class: "w-3 h-3 rounded-full shrink-0",
                    style: "background-color: #{section.effective_color}"
                  )
                  div(class: "min-w-0") do
                    div(class: "font-medium truncate") { section.name }
                    if spending.subcategories_count > 0
                      span(class: "text-xs text-muted-foreground") do
                        plain "#{spending.subcategories_count} #{spending.subcategories_count == 1 ? 'subcategory' : 'subcategories'}"
                      end
                    end
                  end
                end
                if has_limit
                  div(class: "text-right shrink-0") do
                    div(class: "font-mono font-medium") do
                      plain format_currency(spending.spent_this_month)
                      span(class: "text-muted-foreground") { " / " }
                      plain format_currency(spending.limit)
                    end
                    if spending.over_limit
                      span(class: "text-xs text-red-600 dark:text-red-400 font-medium") do
                        plain "Over by #{format_currency(spending.spent_this_month - spending.limit)}"
                      end
                    elsif spending.remaining > 0
                      span(class: "text-xs text-muted-foreground") do
                        plain "#{format_currency(spending.remaining)} remaining"
                      end
                    end
                  end
                else
                  div(class: "text-sm text-muted-foreground shrink-0") do
                    plain "No limit set"
                  end
                end
              end

              # Progress bar
              if has_limit
                div(class: "space-y-1") do
                  div(class: "flex items-center justify-between text-xs") do
                    span(class: "text-muted-foreground") do
                      plain "#{spending.progress_percentage.round}% used"
                    end
                    if spending.remaining > 0
                      span(class: "text-muted-foreground") do
                        plain "#{format_currency(spending.remaining)} left"
                      end
                    end
                  end
                  div(class: "h-2 bg-muted/50 rounded-full overflow-hidden") do
                    div(
                      class: "h-full #{progress_color} transition-all",
                      style: "width: #{[spending.progress_percentage, 100].min}%"
                    )
                  end
                end
              else
                div(class: "text-xs text-muted-foreground") do
                  plain "Spent: #{format_currency(spending.spent_this_month)}"
                end
              end
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
