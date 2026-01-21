# frozen_string_literal: true

module Views
  module Banking
    module PlannedExpenses
      class Calendar < ::Views::Base
        def initialize(planned_expenses:, start_date: nil, weeks: 12)
          @planned_expenses = planned_expenses
          @start_date = start_date || Date.current.beginning_of_week
          @weeks = weeks
        end

        def view_template
          div(
            class: "rounded-lg border bg-card p-4",
            data: { controller: "expense-calendar" }
          ) do
            render_header
            render_calendar_grid
          end
        end

        private

        def render_header
          div(class: "flex items-center justify-between mb-4") do
            div(class: "flex items-center gap-2") do
              render ::Components::Icon::Calendar.new(size: "20")
              h3(class: "font-semibold") { "Expense Calendar" }
            end
            div(class: "text-sm text-muted-foreground") do
              plain "#{@start_date.strftime('%b %d')} - #{end_date.strftime('%b %d, %Y')}"
            end
          end
        end

        def render_calendar_grid
          div(class: "grid grid-cols-7 gap-1") do
            render_day_headers
            render_calendar_days
          end
        end

        def render_day_headers
          %w[Mon Tue Wed Thu Fri Sat Sun].each do |day|
            div(class: "text-center text-xs font-medium text-muted-foreground py-2") { day }
          end
        end

        def render_calendar_days
          current_date = @start_date
          while current_date <= end_date
            render_day_cell(current_date)
            current_date += 1.day
          end
        end

        def render_day_cell(date)
          expenses_on_date = expenses_for_date(date)
          is_today = date == Date.current
          is_past = date < Date.current

          cell_classes = [
            "min-h-16 p-1 border rounded text-xs",
            is_today ? "border-primary bg-primary/10" : "border-transparent",
            is_past ? "opacity-50" : ""
          ].join(" ")

          div(class: cell_classes) do
            div(class: "flex justify-between items-start") do
              span(class: "font-medium #{is_today ? 'text-primary' : ''}") { date.day }
              if expenses_on_date.any?
                span(class: "text-[10px] px-1 rounded bg-muted") { expenses_on_date.size }
              end
            end

            if expenses_on_date.any?
              div(class: "mt-1 space-y-0.5") do
                expenses_on_date.first(2).each do |expense|
                  render_expense_marker(expense)
                end
                if expenses_on_date.size > 2
                  div(class: "text-[10px] text-muted-foreground") { "+#{expenses_on_date.size - 2} more" }
                end
              end
            end
          end
        end

        def render_expense_marker(expense)
          bg_color = if expense.completed
            "bg-green-200 dark:bg-green-800"
          elsif expense.overdue?
            "bg-red-200 dark:bg-red-800"
          else
            "bg-blue-200 dark:bg-blue-800"
          end

          div(
            class: "truncate text-[10px] px-1 rounded #{bg_color}",
            title: "#{expense.description} - #{format_currency(expense.expected_amount)}"
          ) do
            plain expense.description.truncate(12)
          end
        end

        def expenses_for_date(date)
          @expenses_by_date ||= @planned_expenses.group_by(&:due_date)
          @expenses_by_date[date] || []
        end

        def end_date
          @start_date + @weeks.weeks - 1.day
        end

        def format_currency(amount)
          "#{view_context.number_with_delimiter(sprintf('%.2f', amount))}"
        end
      end
    end
  end
end
