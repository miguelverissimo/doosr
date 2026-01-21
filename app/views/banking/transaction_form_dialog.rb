# frozen_string_literal: true

module Views
  module Banking
    class TransactionFormDialog < ::Views::Base
      def initialize(transaction:, categories:)
        @transaction = transaction
        @categories = categories
      end

      def view_template
        div(id: "transaction_dialog") do
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
        @transaction.persisted?
      end

      def dialog_title
        editing? ? "Edit Transaction" : "Add Transaction"
      end

      def dialog_description
        editing? ? "Update the transaction details" : "Create a new bank transaction"
      end

      def form_action
        if editing?
          view_context.update_transaction_banking_path(@transaction)
        else
          view_context.create_transaction_banking_index_path
        end
      end

      def loading_message
        editing? ? "Updating transaction..." : "Creating transaction..."
      end

      def success_message
        editing? ? "Transaction updated successfully" : "Transaction created successfully"
      end

      def submit_button_text
        editing? ? "Update Transaction" : "Create Transaction"
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

          div(id: "transaction_form_errors", class: "text-sm text-destructive")

          render_date_field
          render_description_field
          render_value_field
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

      def render_date_field
        render RubyUI::FormField.new do
          render RubyUI::FormFieldLabel.new(for: "bank_transaction_date") { "Date" }
          render RubyUI::Input.new(
            type: :date,
            id: "bank_transaction_date",
            name: "bank_transaction[date]",
            value: @transaction.date&.to_s,
            required: true,
            class: "date-input-icon-light-dark"
          )
          render RubyUI::FormFieldError.new
        end
      end

      def render_description_field
        render RubyUI::FormField.new do
          render RubyUI::FormFieldLabel.new(for: "bank_transaction_description") { "Description" }
          render RubyUI::Input.new(
            type: :text,
            id: "bank_transaction_description",
            name: "bank_transaction[description]",
            value: @transaction.description,
            required: true,
            placeholder: "e.g., Coffee at Starbucks"
          )
          render RubyUI::FormFieldError.new
        end
      end

      def render_value_field
        render RubyUI::FormField.new do
          render RubyUI::FormFieldLabel.new(for: "bank_transaction_value") { "Amount" }
          p(class: "text-xs text-muted-foreground mb-2") do
            plain "Use negative for expenses (e.g., -24.50), positive for income (e.g., 1500.00)"
          end
          render RubyUI::Input.new(
            type: :number,
            id: "bank_transaction_value",
            name: "bank_transaction[value]",
            value: @transaction.value,
            required: true,
            step: "0.01",
            placeholder: "-24.50"
          )
          render RubyUI::FormFieldError.new
        end
      end

      def render_category_field
        current_category_id = @transaction.primary_category&.id

        render RubyUI::FormField.new do
          render RubyUI::FormFieldLabel.new(for: "category_id") { "Category" }
          select(
            id: "category_id",
            name: "category_id",
            class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
          ) do
            option(value: "") { "Select a category (optional)" }
            render_hierarchical_category_options(current_category_id)
          end
          render RubyUI::FormFieldError.new
        end
      end

      def render_hierarchical_category_options(current_category_id)
        @categories.each do |category|
          if category.respond_to?(:subcategories) && category.subcategories.any?
            optgroup(label: category.name) do
              option(
                value: category.id,
                selected: current_category_id == category.id
              ) { category.name }

              category.subcategories.order(:name).each do |sub|
                option(
                  value: sub.id,
                  selected: current_category_id == sub.id
                ) { "  └ #{sub.name}" }
              end
            end
          else
            option(
              value: category.id,
              selected: current_category_id == category.id
            ) { category.name }
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
