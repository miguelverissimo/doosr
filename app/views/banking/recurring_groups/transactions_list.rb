# frozen_string_literal: true

module Views
  module Banking
    module RecurringGroups
      class TransactionsList < ::Views::Base
        include RubyUI

        def initialize(recurring_group:, transactions:)
          @recurring_group = recurring_group
          @transactions = transactions
        end

        def view_template
          div(id: "recurring_group_transactions", class: "space-y-4") do
            render_back_button
            render_group_header
            render_transactions_table
          end
        end

        private

        def render_back_button
          form(
            action: banking_recurring_groups_path(back_to_list: true),
            method: "get",
            data: { turbo_stream: true },
            class: "inline mb-4"
          ) do
            button(
              type: "submit",
              class: "inline-flex items-center text-sm text-muted-foreground hover:text-foreground"
            ) do
              render ::Components::Icon::ArrowLeft.new(size: "16", class: "mr-1")
              plain "Back to recurring patterns"
            end
          end
        end

        def render_group_header
          div(class: "rounded-lg border bg-muted/50 p-4 mb-4") do
            div(class: "flex items-start justify-between") do
              div do
                div(class: "flex items-center gap-2 mb-2") do
                  h3(class: "text-lg font-semibold") { @recurring_group.name }
                  render_frequency_badge(@recurring_group.frequency)
                end
                div(class: "text-sm text-muted-foreground") do
                  plain "Pattern: "
                  span(class: "font-mono") { @recurring_group.description_pattern }
                end
              end
              div(class: "text-right") do
                div(class: "text-lg font-semibold #{@recurring_group.average_amount >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}") do
                  plain "Avg: #{format_currency(@recurring_group.average_amount)}"
                end
                div(class: "text-xs text-muted-foreground") do
                  plain "~#{format_currency(@recurring_group.monthly_amount)}/month"
                end
              end
            end
          end
        end

        def render_transactions_table
          div(class: "rounded-md border overflow-hidden") do
            render Table.new do
              render TableHeader.new do
                render TableRow.new do
                  render TableHead.new { "Date" }
                  render TableHead.new { "Description" }
                  render TableHead.new(class: "text-right") { "Value" }
                end
              end
              render TableBody.new do
                @transactions.each do |transaction|
                  render_transaction_row(transaction)
                end
              end
            end
          end
        end

        def render_transaction_row(transaction)
          render TableRow.new do
            render TableCell.new do
              span(class: "text-sm") { transaction.date.strftime("%b %d, %Y") }
            end
            render TableCell.new do
              span(class: "text-sm") { transaction.description }
            end
            render TableCell.new(class: "text-right") do
              value_class = transaction.value >= 0 ? "text-green-600 dark:text-green-400" : "text-red-600 dark:text-red-400"
              span(class: "font-medium #{value_class}") { format_currency(transaction.value) }
            end
          end
        end

        def render_frequency_badge(frequency)
          color_class = case frequency
          when "weekly" then "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
          when "monthly" then "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
          when "yearly" then "bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200"
          else "bg-secondary text-secondary-foreground"
          end

          span(class: "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium #{color_class}") do
            plain frequency.capitalize
          end
        end

        def format_currency(amount)
          "€#{number_with_delimiter(sprintf('%.2f', amount))}"
        end
      end
    end
  end
end
