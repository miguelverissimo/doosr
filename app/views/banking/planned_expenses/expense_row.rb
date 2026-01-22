# frozen_string_literal: true

module Views
  module Banking
    module PlannedExpenses
      class ExpenseRow < ::Views::Base
        def initialize(planned_expense:)
          @planned_expense = planned_expense
        end

        def view_template
          div(
            id: "planned_expense_#{@planned_expense.id}",
            class: "flex items-center justify-between p-3 rounded-lg border bg-card #{row_classes}"
          ) do
            render_expense_info
            render_actions
          end
        end

        private

        def row_classes
          if @planned_expense.completed
            "opacity-60"
          elsif @planned_expense.overdue?
            "border-red-300 bg-red-50 dark:border-red-800 dark:bg-red-950"
          else
            ""
          end
        end

        def render_expense_info
          div(class: "flex items-center gap-3") do
            render_type_indicator
            div do
              div(class: "flex items-center gap-2") do
                span(class: "font-medium #{@planned_expense.completed ? 'line-through text-muted-foreground' : ''}") do
                  plain @planned_expense.description
                end
                render_category_badge if @planned_expense.category
              end
              div(class: "flex items-center gap-2 text-sm text-muted-foreground") do
                span { format_currency(@planned_expense.expected_amount) }
                span { "" }
                render_due_date
              end
            end
          end
        end

        def render_type_indicator
          if @planned_expense.recurring_auto?
            render ::Components::Icon::Repeat.new(size: "16", class: "text-blue-500")
          else
            render ::Components::Icon::Calendar.new(size: "16", class: "text-muted-foreground")
          end
        end

        def render_category_badge
          div(
            class: "w-3 h-3 rounded-full",
            style: "background-color: #{@planned_expense.category.color}",
            title: @planned_expense.category.name
          )
        end

        def render_due_date
          if @planned_expense.overdue?
            span(class: "text-red-500 font-medium") do
              plain "Overdue: #{format_date(@planned_expense.due_date)}"
            end
          else
            span { format_date(@planned_expense.due_date) }
          end
        end

        def render_actions
          div(class: "flex items-center gap-1") do
            unless @planned_expense.completed
              render_complete_button
            end
            render_edit_button unless @planned_expense.recurring_auto?
            render_delete_button
          end
        end

        def render_complete_button
          form(
            action: view_context.mark_completed_banking_planned_expense_path(@planned_expense),
            method: "post",
            data: {
              controller: "form-loading",
              form_loading_message_value: "Marking as completed...",
              turbo: true
            }
          ) do
            render RubyUI::Input.new(
              type: :hidden,
              name: "authenticity_token",
              value: view_context.form_authenticity_token
            )
            render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch")
            button(
              type: "submit",
              class: "p-2 rounded-md hover:bg-green-100 dark:hover:bg-green-900 text-green-600",
              title: "Mark as completed"
            ) do
              render ::Components::Icon::Check.new(size: "16")
            end
          end
        end

        def render_edit_button
          button(
            type: "button",
            class: "p-2 rounded-md hover:bg-accent",
            data: {
              controller: "enable-dialog",
              enable_dialog_url_value: view_context.edit_banking_planned_expense_path(@planned_expense),
              action: "click->enable-dialog#openDialog"
            }
          ) do
            render ::Components::Icon::Edit.new(size: "16")
          end
        end

        def render_delete_button
          button(
            type: "button",
            class: "p-2 rounded-md hover:bg-destructive/10 text-destructive",
            data: {
              controller: "delete-confirm",
              delete_confirm_url_value: view_context.banking_planned_expense_path(@planned_expense),
              delete_confirm_message_value: "Are you sure you want to delete this expense?",
              action: "click->delete-confirm#confirm"
            }
          ) do
            render ::Components::Icon::Trash.new(size: "16")
          end
        end

        def format_currency(amount)
          "#{view_context.number_with_delimiter(sprintf('%.2f', amount))}"
        end

        def format_date(date)
          if date.year == Date.current.year
            date.strftime("%b %d")
          else
            date.strftime("%b %d, %Y")
          end
        end
      end
    end
  end
end
