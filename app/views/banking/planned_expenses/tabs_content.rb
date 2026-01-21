# frozen_string_literal: true

module Views
  module Banking
    module PlannedExpenses
      class TabsContent < ::Views::Base
        def initialize(planned_expenses:)
          @planned_expenses = planned_expenses
        end

        def view_template
          div(id: "planned_expenses_content") do
            render_tabs
            render_action_buttons
          end
        end

        private

        def render_tabs
          div(data: { controller: "tabs" }) do
            div(class: "flex gap-2 mb-4") do
              render_tab_button("upcoming", "Upcoming", true)
              render_tab_button("completed", "Completed", false)
              render_tab_button("overdue", "Overdue", false)
            end

            render_tab_panel("upcoming", upcoming_expenses, true)
            render_tab_panel("completed", completed_expenses, false)
            render_tab_panel("overdue", overdue_expenses, false)
          end
        end

        def render_tab_button(id, label, active)
          button(
            type: "button",
            class: "px-4 py-2 text-sm font-medium rounded-md transition-colors #{active ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground hover:bg-accent'}",
            data: {
              action: "click->tabs#switch",
              tabs_target: "tab",
              tab_id: id
            }
          ) { label }
        end

        def render_tab_panel(id, expenses, active)
          div(
            data: { tabs_target: "panel", panel_id: id },
            class: active ? "" : "hidden"
          ) do
            if expenses.empty?
              render_empty_state(id)
            else
              div(class: "space-y-2 max-h-96 overflow-y-auto") do
                expenses.each do |expense|
                  render ::Views::Banking::PlannedExpenses::ExpenseRow.new(planned_expense: expense)
                end
              end
            end
          end
        end

        def render_empty_state(type)
          message = case type
          when "upcoming" then "No upcoming expenses"
          when "completed" then "No completed expenses"
          when "overdue" then "No overdue expenses"
          else "No expenses"
          end

          div(class: "text-center py-8") do
            render ::Components::Icon::Calendar.new(size: "48", class: "mx-auto text-muted-foreground mb-4")
            p(class: "text-muted-foreground") { message }
          end
        end

        def render_action_buttons
          div(class: "flex gap-2 mt-4") do
            button(
              type: "button",
              class: "flex-1 inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-dashed border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2",
              data: {
                controller: "enable-dialog",
                enable_dialog_url_value: view_context.new_banking_planned_expense_path,
                action: "click->enable-dialog#openDialog"
              }
            ) do
              render ::Components::Icon::Add.new(size: "16", class: "mr-2")
              plain "Add Expense"
            end

            form(
              action: view_context.populate_from_recurring_banking_planned_expenses_path,
              method: "post",
              data: { turbo: true }
            ) do
              render RubyUI::Input.new(
                type: :hidden,
                name: "authenticity_token",
                value: view_context.form_authenticity_token
              )
              Button(variant: :outline, type: "submit") do
                render ::Components::Icon::Refresh.new(size: "16", class: "mr-2")
                plain "Populate from Recurring"
              end
            end
          end
        end

        def upcoming_expenses
          @planned_expenses.select { |e| !e.completed && e.due_date >= Date.current }
        end

        def completed_expenses
          @planned_expenses.select(&:completed)
        end

        def overdue_expenses
          @planned_expenses.select { |e| !e.completed && e.due_date < Date.current }
        end
      end
    end
  end
end
