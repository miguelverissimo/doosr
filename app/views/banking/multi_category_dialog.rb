# frozen_string_literal: true

module Views
  module Banking
    class MultiCategoryDialog < ::Views::Base
      include RubyUI

      def initialize(transaction:, categories:)
        @transaction = transaction
        @categories = categories
      end

      def view_template
        render Dialog.new(id: "multi_category_dialog", open: true) do
          render DialogContent.new(class: "max-w-lg") do
            render DialogHeader.new do
              render DialogTitle.new { "Categorize Transaction" }
              render DialogDescription.new do
                div(class: "space-y-1") do
                  div { @transaction.description }
                  div(class: "font-mono #{value_color}") { format_currency(@transaction.value) }
                end
              end
            end

            render_form
          end
        end
      end

      private

      def render_form
        div(
          data: {
            controller: "multi-category-form",
            multi_category_form_transaction_amount_value: @transaction.value.abs
          }
        ) do
          form(
            action: view_context.update_categories_banking_path(@transaction),
            method: "post",
            class: "space-y-4 mt-4"
          ) do
            csrf_token_field
            render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch")

            div(id: "multi_category_form_errors", class: "text-sm text-destructive")

            render_category_rows
            render_add_row_button
            render_remaining_amount
            render_actions
          end

          render_row_template
        end
      end

      def csrf_token_field
        render RubyUI::Input.new(
          type: :hidden,
          name: "authenticity_token",
          value: view_context.form_authenticity_token
        )
      end

      def render_category_rows
        div(data: { multi_category_form_target: "rowsContainer" }, class: "space-y-3") do
          existing_categorizations = @transaction.transaction_categorizations.includes(:category)

          if existing_categorizations.any?
            existing_categorizations.each_with_index do |tc, index|
              render_category_row(index, tc.category_id, tc.amount)
            end
          else
            render_category_row(0, nil, nil)
          end
        end
      end

      def render_category_row(index, category_id, amount)
        div(data: { row: true }, class: "flex items-center gap-2") do
          render_category_select(index, category_id)
          render_amount_input(index, amount)
          render_remove_button
        end
      end

      def render_category_select(index, selected_category_id)
        select(
          name: "category_ids[]",
          class: "flex h-10 flex-1 rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
        ) do
          option(value: "") { "Select category..." }
          render_category_options(selected_category_id)
        end
      end

      def render_category_options(selected_category_id)
        @categories.each do |category|
          if category.subcategories.any?
            optgroup(label: category.name) do
              option(
                value: category.id,
                selected: selected_category_id == category.id
              ) { category.name }

              category.subcategories.order(:name).each do |sub|
                option(
                  value: sub.id,
                  selected: selected_category_id == sub.id
                ) { "  └ #{sub.name}" }
              end
            end
          else
            option(
              value: category.id,
              selected: selected_category_id == category.id
            ) { category.name }
          end
        end
      end

      def render_amount_input(index, amount)
        render RubyUI::Input.new(
          type: :number,
          name: "amounts[#{index}]",
          value: amount,
          placeholder: "Amount (optional)",
          step: "0.01",
          min: "0",
          max: @transaction.value.abs.to_s,
          class: "w-32",
          data: { action: "input->multi-category-form#updateRemainingAmount" }
        )
      end

      def render_remove_button
        button(
          type: "button",
          class: "inline-flex items-center justify-center h-10 w-10 rounded-md text-muted-foreground hover:bg-muted hover:text-foreground transition-colors",
          data: { action: "click->multi-category-form#removeRow" }
        ) do
          render ::Components::Icon::Trash.new(size: "16")
        end
      end

      def render_add_row_button
        button(
          type: "button",
          class: "inline-flex items-center text-sm text-muted-foreground hover:text-foreground",
          data: { action: "click->multi-category-form#addRow" }
        ) do
          render ::Components::Icon::Add.new(size: "16", class: "mr-1")
          plain "Add another category"
        end
      end

      def render_remaining_amount
        div(class: "flex items-center justify-between text-sm pt-2 border-t") do
          span { "Transaction total:" }
          span(class: "font-mono font-medium") { format_currency(@transaction.value.abs) }
        end
        div(class: "flex items-center justify-between text-sm") do
          span { "Remaining unallocated:" }
          span(
            class: "font-mono text-muted-foreground",
            data: { multi_category_form_target: "remainingAmount" }
          ) { @transaction.value.abs.to_s }
        end
        div(class: "text-xs text-muted-foreground") do
          plain "Leave amounts blank to apply full transaction value to each category"
        end
      end

      def render_actions
        div(class: "flex gap-2 justify-end mt-6") do
          button(
            type: "button",
            class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2",
            data: {
              action: "click->modal-form#cancelDialog",
              modal_form_dialog_id_param: "multi_category_dialog"
            }
          ) { "Cancel" }
          Button(variant: :primary, type: "submit") { "Save" }
        end
      end

      def render_row_template
        template_tag(data: { multi_category_form_target: "rowTemplate" }) do
          div(data: { row: true }, class: "flex items-center gap-2") do
            render_category_select(0, nil)
            render_amount_input(0, nil)
            render_remove_button
          end
        end
      end

      def value_color
        @transaction.value.negative? ? "text-red-600 dark:text-red-400" : "text-green-600 dark:text-green-400"
      end

      def format_currency(amount)
        sign = amount.negative? ? "-" : "+"
        "#{sign}€#{number_with_delimiter(sprintf('%.2f', amount.abs))}"
      end
    end
  end
end
