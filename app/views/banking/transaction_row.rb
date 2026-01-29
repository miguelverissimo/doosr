# frozen_string_literal: true

module Views
  module Banking
    class TransactionRow < ::Views::Base
      include RubyUI

      def initialize(transaction:, categories: [])
        @transaction = transaction
        @categories = categories
      end

      def view_template
        TableRow(id: "transaction_#{@transaction.id}", class: "text-xs") do
          TableCell(class: "w-6 px-1") { render_account_circle if @transaction.bank_account.present? }
          TableCell(class: "w-20 whitespace-nowrap px-2") { @transaction.date.strftime("%b %d, %Y") }
          TableCell(class: "px-2") { render_description }
          TableCell(class: "whitespace-nowrap px-2") { render_category_selector }
          TableCell(class: "text-right font-mono whitespace-nowrap px-2 #{value_color(@transaction.value)}") do
            format_currency(@transaction.value)
          end
        end
      end

      private

      def render_description
        div(class: "flex items-center gap-2") do
          div(class: "truncate flex-1 min-w-0") do
            span { @transaction.description }
            render_transfer_badge if @transaction.is_transfer
            if pattern_label.present?
              span(class: "ml-2 text-xs text-muted-foreground bg-muted px-1.5 py-0.5 rounded") do
                plain pattern_label
              end
            end
          end
          render_create_pattern_button
        end
      end

      def render_transfer_badge
        span(class: "ml-2 inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200") do
          render ::Components::Icon::ArrowLeftRight.new(size: "10")
          plain "Transfer"
        end
      end

      def render_account_circle
        account = @transaction.bank_account
        div(
          class: "inline-flex items-center justify-center w-5 h-5 rounded-full text-[10px] font-bold shrink-0",
          style: "background-color: #{account.bg_color}; color: #{account.fg_color};",
          title: account.name
        ) do
          plain account.display_letter
        end
      end

      def pattern_label
        @transaction.category_pattern&.label
      end

      def render_create_pattern_button
        button(
          type: "button",
          class: "shrink-0 text-muted-foreground hover:text-foreground transition-colors",
          title: "Create auto-categorization pattern",
          data: {
            controller: "create-pattern",
            action: "click->create-pattern#openDialog",
            create_pattern_url_value: view_context.new_banking_category_pattern_path(transaction_id: @transaction.id)
          }
        ) do
          render ::Components::Icon::Wand.new(size: "12")
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
