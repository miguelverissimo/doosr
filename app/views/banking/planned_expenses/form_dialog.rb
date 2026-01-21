# frozen_string_literal: true

module Views
  module Banking
    module PlannedExpenses
      class FormDialog < ::Views::Base
        def initialize(planned_expense:, categories:)
          @planned_expense = planned_expense
          @categories = categories
        end

        def view_template
          div(id: "planned_expense_form_dialog") do
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
          @planned_expense.persisted?
        end

        def dialog_title
          editing? ? "Edit Planned Expense" : "Add Planned Expense"
        end

        def dialog_description
          editing? ? "Update your planned expense details" : "Add a one-time upcoming expense"
        end

        def form_action
          if editing?
            view_context.banking_planned_expense_path(@planned_expense)
          else
            view_context.banking_planned_expenses_path
          end
        end

        def loading_message
          editing? ? "Updating expense..." : "Creating expense..."
        end

        def success_message
          editing? ? "Expense updated successfully" : "Expense created successfully"
        end

        def submit_button_text
          editing? ? "Update Expense" : "Add Expense"
        end

        def render_form
          form(
            action: form_action,
            method: "post",
            data: {
              controller: "modal-form",
              modal_form_loading_message_value: loading_message,
              modal_form_success_message_value: success_message,
              turbo: true
            },
            class: "space-y-4"
          ) do
            csrf_token_field
            render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch") if editing?

            div(id: "planned_expense_form_errors", class: "text-sm text-destructive")

            render_description_field
            render_amount_field
            render_due_date_field
            render_category_field

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

        def render_description_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "planned_expense_description") { "Description" }
            render RubyUI::Input.new(
              type: :text,
              id: "planned_expense_description",
              name: "planned_expense[description]",
              value: @planned_expense.description,
              required: true,
              placeholder: "e.g., Annual Insurance Premium"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_amount_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "planned_expense_expected_amount") { "Expected Amount" }
            render RubyUI::Input.new(
              type: :number,
              id: "planned_expense_expected_amount",
              name: "planned_expense[expected_amount]",
              value: @planned_expense.expected_amount,
              required: true,
              step: "0.01",
              min: "0.01",
              placeholder: "e.g., 150.00"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_due_date_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "planned_expense_due_date") { "Due Date" }
            render RubyUI::Input.new(
              type: :date,
              id: "planned_expense_due_date",
              name: "planned_expense[due_date]",
              value: @planned_expense.due_date&.to_s,
              required: true,
              class: "date-input-icon-light-dark"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_category_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "planned_expense_category_id") { "Category (Optional)" }
            select(
              id: "planned_expense_category_id",
              name: "planned_expense[category_id]",
              class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
            ) do
              option(value: "") { "No category" }
              @categories.each do |category|
                option(
                  value: category.id,
                  selected: @planned_expense.category_id == category.id
                ) { category.name }
              end
            end
            render RubyUI::FormFieldError.new
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
