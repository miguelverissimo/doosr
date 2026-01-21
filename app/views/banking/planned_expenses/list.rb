# frozen_string_literal: true

module Views
  module Banking
    module PlannedExpenses
      class List < ::Views::Base
        def initialize(planned_expenses:, show_header: true)
          @planned_expenses = planned_expenses
          @show_header = show_header
        end

        def view_template
          div(id: "planned_expenses_list", class: "rounded-lg border bg-card") do
            render_header if @show_header
            render_content
          end
        end

        private

        def render_header
          div(class: "flex items-center justify-between p-4 border-b") do
            div(class: "flex items-center gap-2") do
              render ::Components::Icon::Calendar.new(size: "20")
              h3(class: "font-semibold") { "Upcoming Expenses" }
            end
            button(
              type: "button",
              class: "text-sm text-primary hover:underline",
              data: {
                controller: "enable-dialog",
                enable_dialog_url_value: view_context.banking_planned_expenses_path,
                action: "click->enable-dialog#openDialog"
              }
            ) { "View All" }
          end
        end

        def render_content
          if @planned_expenses.empty?
            render_empty_state
          else
            div(class: "divide-y") do
              @planned_expenses.first(5).each do |expense|
                render_expense_item(expense)
              end
            end

            if @planned_expenses.size > 5
              div(class: "p-3 text-center text-sm text-muted-foreground") do
                plain "and #{@planned_expenses.size - 5} more..."
              end
            end
          end
        end

        def render_empty_state
          div(class: "p-6 text-center") do
            p(class: "text-muted-foreground") { "No upcoming expenses" }
            button(
              type: "button",
              class: "mt-2 text-sm text-primary hover:underline",
              data: {
                controller: "enable-dialog",
                enable_dialog_url_value: view_context.new_banking_planned_expense_path,
                action: "click->enable-dialog#openDialog"
              }
            ) { "Add one" }
          end
        end

        def render_expense_item(expense)
          div(class: "flex items-center justify-between p-3 hover:bg-muted/50") do
            div(class: "flex items-center gap-3") do
              render_date_badge(expense.due_date)
              div do
                p(class: "font-medium text-sm") { expense.description }
                p(class: "text-xs text-muted-foreground") { expense.expense_type_label }
              end
            end
            span(class: "font-medium") { format_currency(expense.expected_amount) }
          end
        end

        def render_date_badge(date)
          days_until = (date - Date.current).to_i
          bg_color = if days_until < 0
            "bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300"
          elsif days_until <= 7
            "bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-300"
          else
            "bg-muted text-muted-foreground"
          end

          div(class: "flex flex-col items-center justify-center w-12 h-12 rounded-lg #{bg_color}") do
            span(class: "text-xs font-medium") { date.strftime("%b") }
            span(class: "text-lg font-bold leading-none") { date.day }
          end
        end

        def format_currency(amount)
          "#{view_context.number_with_delimiter(sprintf('%.2f', amount))}"
        end
      end
    end
  end
end
