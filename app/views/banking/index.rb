# frozen_string_literal: true

module Views
  module Banking
    class Index < ::Views::Base
      def initialize(user:, start_date:, end_date:, total_income:, total_expenses:, net_balance:, income_change:, expenses_change:, balance_change:, category_breakdown:, time_series_data:, time_series_granularity:, transactions:, page: 1, sort_column: "date", sort_direction: "desc", category_id: nil, min_amount: nil, max_amount: nil, search: nil)
        @user = user
        @start_date = start_date
        @end_date = end_date
        @total_income = total_income
        @total_expenses = total_expenses
        @net_balance = net_balance
        @income_change = income_change
        @expenses_change = expenses_change
        @balance_change = balance_change
        @category_breakdown = category_breakdown
        @time_series_data = time_series_data
        @time_series_granularity = time_series_granularity
        @transactions = transactions
        @page = page
        @sort_column = sort_column
        @sort_direction = sort_direction
        @category_id = category_id
        @min_amount = min_amount
        @max_amount = max_amount
        @search = search
      end

      def view_template
        div(
          class: "flex h-full flex-col space-y-6",
          data: {
            controller: "banking-import banking-recurring",
            banking_import_user_id_value: @user.id,
            banking_recurring_user_id_value: @user.id
          }
        ) do
          render_summary_cards
          render_charts_section
          render_transactions_section
        end
      end

      private

      def render_summary_cards
        div(class: "grid gap-4 md:grid-cols-3") do
          render_card(
            title: "Total Income",
            value: format_currency(@total_income),
            color: "text-green-600 dark:text-green-400",
            change: @income_change,
            positive_is_good: true
          )
          render_card(
            title: "Total Expenses",
            value: format_currency(@total_expenses),
            color: "text-red-600 dark:text-red-400",
            change: @expenses_change,
            positive_is_good: false
          )
          render_card(
            title: "Net Balance",
            value: format_currency(@net_balance),
            color: @net_balance >= 0 ? "text-blue-600 dark:text-blue-400" : "text-red-600 dark:text-red-400",
            change: @balance_change,
            positive_is_good: true
          )
        end
      end

      def render_card(title:, value:, color:, change: nil, positive_is_good: true)
        div(class: "rounded-lg border bg-card p-6 shadow-sm") do
          div(class: "flex flex-row items-center justify-between space-y-0 pb-2") do
            h3(class: "text-sm font-medium text-muted-foreground tracking-tight") { title }
          end
          div(class: "flex items-baseline gap-2") do
            div(class: "text-2xl font-bold #{color}") { value }
            render_change_indicator(change, positive_is_good) if change
          end
          div(class: "text-xs text-muted-foreground mt-1") do
            plain date_range_text
          end
        end
      end

      def render_change_indicator(change, positive_is_good)
        return if change.nil?

        is_positive = change.positive?
        is_good = (is_positive && positive_is_good) || (!is_positive && !positive_is_good)

        indicator_color = if is_good
          "text-green-600 dark:text-green-400"
        else
          "text-red-600 dark:text-red-400"
        end

        span(class: "inline-flex items-center text-xs font-medium #{indicator_color}") do
          if is_positive
            render ::Components::Icon::ArrowUp.new(size: "12", class: "mr-0.5")
            plain "+#{change.abs}%"
          else
            render ::Components::Icon::ArrowDown.new(size: "12", class: "mr-0.5")
            plain "-#{change.abs}%"
          end
        end
      end

      def render_charts_section
        div(class: "grid gap-6 lg:grid-cols-2") do
          render ::Views::Banking::CategoryBreakdownChart.new(
            category_breakdown: @category_breakdown,
            start_date: @start_date,
            end_date: @end_date,
            category_id: @category_id
          )
          render ::Views::Banking::SpendingOverTimeChart.new(
            time_series_data: @time_series_data,
            start_date: @start_date,
            end_date: @end_date,
            granularity: @time_series_granularity
          )
        end
      end

      def render_transactions_section
        div(
          class: "rounded-lg border bg-card shadow-sm",
          data: { controller: "transactions-pagination" }
        ) do
          div(class: "p-6") do
            div(class: "flex items-center justify-between mb-4") do
              div(class: "flex items-center gap-2") do
                h3(class: "text-lg font-semibold") { "Transactions" }
                div(class: "text-sm text-muted-foreground") do
                  plain "#{@transactions.total_count} total"
                end
              end
              div(class: "flex items-center gap-2") do
                render_recurring_button
                render_manage_patterns_button
                render_manage_categories_button
                render_import_csv_button
                render_add_transaction_button
              end
            end

            render ::Views::Banking::FilterPanel.new(
              user: @user,
              start_date: @start_date,
              end_date: @end_date,
              category_id: @category_id,
              min_amount: @min_amount,
              max_amount: @max_amount,
              search: @search,
              sort_column: @sort_column,
              sort_direction: @sort_direction
            )

            render_loading_spinner
            render ::Views::Banking::TransactionsList.new(
              user: @user,
              transactions: @transactions,
              page: @page,
              start_date: @start_date,
              end_date: @end_date,
              sort_column: @sort_column,
              sort_direction: @sort_direction,
              category_id: @category_id,
              min_amount: @min_amount,
              max_amount: @max_amount,
              search: @search
            )
          end
        end
      end

      def render_loading_spinner
        div(
          id: "transactions_loading_spinner",
          class: "hidden",
          data: { transactions_pagination_target: "spinner" }
        ) do
          render ::Components::Shared::LoadingSpinner.new(message: "Loading transactions...")
        end
      end

      def format_currency(amount)
        "€#{number_with_delimiter(sprintf('%.2f', amount))}"
      end

      def date_range_text
        if @start_date.nil? && @end_date.nil?
          "All Time"
        elsif @start_date && @end_date
          "#{@start_date.strftime('%b %d')} - #{@end_date.strftime('%b %d, %Y')}"
        elsif @start_date
          "From #{@start_date.strftime('%b %d, %Y')}"
        else
          "Until #{@end_date.strftime('%b %d, %Y')}"
        end
      end

      def render_recurring_button
        button(
          type: "button",
          class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2",
          data: {
            controller: "enable-dialog",
            enable_dialog_url_value: banking_recurring_groups_path,
            action: "click->enable-dialog#openDialog"
          }
        ) do
          render ::Components::Icon::Repeat.new(size: "16", class: "mr-2")
          plain "Recurring"
        end
      end

      def render_manage_patterns_button
        button(
          type: "button",
          class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2",
          data: {
            controller: "enable-dialog",
            enable_dialog_url_value: banking_category_patterns_path,
            action: "click->enable-dialog#openDialog"
          }
        ) do
          render ::Components::Icon::Wand.new(size: "16", class: "mr-2")
          plain "Manage Patterns"
        end
      end

      def render_manage_categories_button
        button(
          type: "button",
          class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2",
          data: {
            controller: "enable-dialog",
            enable_dialog_url_value: banking_categories_path,
            action: "click->enable-dialog#openDialog"
          }
        ) do
          render ::Components::Icon::Tags.new(size: "16", class: "mr-2")
          plain "Manage Categories"
        end
      end

      def render_import_csv_button
        button(
          type: "button",
          class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2",
          data: {
            controller: "enable-dialog",
            enable_dialog_url_value: new_csv_import_banking_index_path,
            action: "click->enable-dialog#openDialog"
          }
        ) do
          render ::Components::Icon::Upload.new(size: "16", class: "mr-2")
          plain "Import CSV"
        end
      end

      def render_add_transaction_button
        button(
          type: "button",
          class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2",
          data: {
            controller: "enable-dialog",
            enable_dialog_url_value: new_transaction_banking_index_path,
            action: "click->enable-dialog#openDialog"
          }
        ) do
          render ::Components::Icon::Add.new(size: "16", class: "mr-2")
          plain "Add Transaction"
        end
      end
    end
  end
end
