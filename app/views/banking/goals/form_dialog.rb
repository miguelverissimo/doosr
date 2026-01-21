# frozen_string_literal: true

module Views
  module Banking
    module Goals
      class FormDialog < ::Views::Base
        def initialize(budget_goal:, categories:)
          @budget_goal = budget_goal
          @categories = categories
        end

        def view_template
          div(id: "budget_goal_form_dialog") do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { dialog_title }
                  render RubyUI::DialogDescription.new { dialog_description }
                end

                render RubyUI::DialogMiddle.new do
                  render_form
                end
              end
            end
          end
        end

        private

        def editing?
          @budget_goal.persisted?
        end

        def dialog_title
          editing? ? "Edit Goal" : "Create Budget Goal"
        end

        def dialog_description
          editing? ? "Update your budget goal settings" : "Set a savings target, category limit, or scheduled payment goal"
        end

        def form_action
          if editing?
            view_context.banking_budget_goal_path(@budget_goal)
          else
            view_context.banking_budget_goals_path
          end
        end

        def loading_message
          editing? ? "Updating goal..." : "Creating goal..."
        end

        def success_message
          editing? ? "Goal updated successfully" : "Goal created successfully"
        end

        def submit_button_text
          editing? ? "Update Goal" : "Create Goal"
        end

        def render_form
          form(
            action: form_action,
            method: "post",
            data: {
              controller: "modal-form budget-goal-form",
              modal_form_loading_message_value: loading_message,
              modal_form_success_message_value: success_message,
              turbo: true
            },
            class: "space-y-4"
          ) do
            csrf_token_field
            render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch") if editing?

            div(id: "budget_goal_form_errors", class: "text-sm text-destructive")

            render_name_field
            render_goal_type_field
            render_category_field
            render_target_amount_field
            render_period_field
            render_payment_months_field
            render_start_date_field
            render_active_field if editing?

            render_actions
          end
        end

        def csrf_token_field
          render RubyUI::Input.new(
            type: :hidden,
            name: "authenticity_token",
            value: view_context.form_authenticity_token
          )
        end

        def render_name_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "budget_goal_name") { "Name (Optional)" }
            render RubyUI::Input.new(
              type: :text,
              id: "budget_goal_name",
              name: "budget_goal[name]",
              value: @budget_goal.name,
              placeholder: "e.g., Quarterly Taxes, Emergency Fund"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_goal_type_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "budget_goal_goal_type") { "Goal Type" }
            select(
              id: "budget_goal_goal_type",
              name: "budget_goal[goal_type]",
              class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
              required: true,
              data: { action: "change->budget-goal-form#toggleGoalType", budget_goal_form_target: "goalType" }
            ) do
              option(value: "savings", selected: @budget_goal.goal_type == "savings") { "Savings Target" }
              option(value: "category_limit", selected: @budget_goal.goal_type == "category_limit") { "Category Budget Limit" }
            end
            render RubyUI::FormFieldError.new
          end
        end

        def render_category_field
          div(
            data: { budget_goal_form_target: "categoryField" },
            class: @budget_goal.category_limit? ? "" : "hidden"
          ) do
            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new(for: "budget_goal_category_id") { "Category" }
              select(
                id: "budget_goal_category_id",
                name: "budget_goal[category_id]",
                class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
              ) do
                option(value: "") { "Select a category" }
                @categories.each do |category|
                  option(
                    value: category.id,
                    selected: @budget_goal.category_id == category.id
                  ) { category.name }
                end
              end
              render RubyUI::FormFieldError.new
            end
          end
        end

        def render_target_amount_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "budget_goal_target_amount") { "Target Amount" }
            p(class: "text-xs text-muted-foreground mb-2", data: { budget_goal_form_target: "amountHint" }) do
              plain amount_hint_text
            end
            render RubyUI::Input.new(
              type: :number,
              id: "budget_goal_target_amount",
              name: "budget_goal[target_amount]",
              value: @budget_goal.target_amount,
              required: true,
              step: "0.01",
              min: "0.01",
              placeholder: "e.g., 500.00"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def amount_hint_text
          case @budget_goal.period
          when "quarterly", "custom"
            "Amount needed per payment period"
          else
            "The amount per period (will be prorated for progress tracking)"
          end
        end

        def render_period_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "budget_goal_period") { "Period" }
            select(
              id: "budget_goal_period",
              name: "budget_goal[period]",
              class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
              required: true,
              data: { action: "change->budget-goal-form#togglePeriod", budget_goal_form_target: "period" }
            ) do
              option(value: "weekly", selected: @budget_goal.period == "weekly") { "Weekly" }
              option(value: "monthly", selected: @budget_goal.period == "monthly") { "Monthly" }
              option(value: "quarterly", selected: @budget_goal.period == "quarterly") { "Quarterly (Mar, Jun, Sep, Dec)" }
              option(value: "yearly", selected: @budget_goal.period == "yearly") { "Yearly" }
              option(value: "custom", selected: @budget_goal.period == "custom") { "Custom (select months)" }
            end
            render RubyUI::FormFieldError.new
          end
        end

        def render_payment_months_field
          div(
            data: { budget_goal_form_target: "paymentMonthsField" },
            class: @budget_goal.custom? ? "" : "hidden"
          ) do
            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Payment Months" }
              p(class: "text-xs text-muted-foreground mb-2") do
                plain "Select the months when payment is due"
              end
              div(class: "grid grid-cols-4 gap-2") do
                BudgetGoal::MONTH_NAMES.each do |month_num, month_name|
                  render_month_checkbox(month_num, month_name)
                end
              end
              render RubyUI::FormFieldError.new
            end
          end
        end

        def render_month_checkbox(month_num, month_name)
          checked = @budget_goal.payment_months&.include?(month_num)
          div(class: "flex items-center space-x-2") do
            input(
              type: "checkbox",
              id: "budget_goal_payment_months_#{month_num}",
              name: "budget_goal[payment_months][]",
              value: month_num.to_s,
              checked: checked,
              class: "h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
            )
            label(
              for: "budget_goal_payment_months_#{month_num}",
              class: "text-sm font-medium leading-none"
            ) { month_name.first(3) }
          end
        end

        def render_start_date_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "budget_goal_start_date") { "Start Date (Optional)" }
            p(class: "text-xs text-muted-foreground mb-2") do
              plain "When to start tracking this goal. Defaults to today."
            end
            render RubyUI::Input.new(
              type: :date,
              id: "budget_goal_start_date",
              name: "budget_goal[start_date]",
              value: @budget_goal.start_date&.to_s,
              class: "date-input-icon-light-dark"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_active_field
          div(class: "flex items-center space-x-2") do
            input(
              type: "checkbox",
              id: "budget_goal_active",
              name: "budget_goal[active]",
              value: "1",
              checked: @budget_goal.active?,
              class: "h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
            )
            label(for: "budget_goal_active", class: "text-sm font-medium leading-none") do
              plain "Active"
            end
          end
        end

        def render_actions
          div(class: "flex gap-2 justify-end mt-6") do
            Button(variant: :outline, type: "button", data: { action: "click->modal-form#cancelDialog" }) { "Cancel" }
            Button(variant: :primary, type: "submit") { submit_button_text }
          end
        end
      end
    end
  end
end
