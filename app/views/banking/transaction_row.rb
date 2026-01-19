# frozen_string_literal: true

module Views
  module Banking
    class TransactionRow < ::Views::Base
      include RubyUI

      def initialize(transaction:, show_checkbox: false, categories: [])
        @transaction = transaction
        @show_checkbox = show_checkbox
        @categories = categories
      end

      def view_template
        TableRow(id: "transaction_#{@transaction.id}") do
          render_checkbox if @show_checkbox
          TableCell { @transaction.date.strftime("%b %d, %Y") }
          TableCell(class: "max-w-xs truncate") { @transaction.description }
          TableCell { render_category_selector }
          TableCell(class: "text-right font-mono #{value_color(@transaction.value)}") do
            format_currency(@transaction.value)
          end
          TableCell(class: "text-right") do
            render_create_pattern_button
          end
        end
      end

      private

      def render_checkbox
        TableCell(class: "w-10") do
          input(
            type: "checkbox",
            value: @transaction.id.to_s,
            class: "peer h-4 w-4 shrink-0 rounded-sm border border-primary ring-offset-background accent-primary",
            data: {
              bulk_select_transactions_target: "checkbox",
              action: "change->bulk-select-transactions#toggleOne"
            }
          )
        end
      end

      def render_create_pattern_button
        Button(
          variant: :ghost,
          size: :sm,
          title: "Create auto-categorization pattern",
          data: {
            controller: "create-pattern",
            action: "click->create-pattern#openDialog",
            create_pattern_url_value: view_context.new_banking_category_pattern_path(transaction_id: @transaction.id)
          }
        ) do
          render ::Components::Icon::Wand.new(size: "16")
        end
      end

      def render_category_selector
        render ::Views::Banking::CategorySelector.new(
          transaction: @transaction,
          categories: @categories
        )
      end

      def value_color(value)
        if value.negative?
          "text-red-600 dark:text-red-400"
        else
          "text-green-600 dark:text-green-400"
        end
      end

      def format_currency(amount)
        sign = amount.negative? ? "-" : "+"
        "#{sign}€#{number_with_delimiter(sprintf('%.2f', amount.abs))}"
      end
    end
  end
end
