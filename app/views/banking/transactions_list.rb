# frozen_string_literal: true

module Views
  module Banking
    class TransactionsList < ::Views::Base
      include RubyUI

      SORTABLE_COLUMNS = {
        "date" => "Date",
        "description" => "Description",
        "category" => "Category",
        "value" => "Value"
      }.freeze

      def initialize(user:, transactions:, page: 1, start_date: nil, end_date: nil, sort_column: "date", sort_direction: "desc", category_id: nil, min_amount: nil, max_amount: nil, search: nil, categories: [], **attrs)
        @user = user
        @transactions = transactions
        @page = page
        @start_date = start_date
        @end_date = end_date
        @sort_column = sort_column
        @sort_direction = sort_direction
        @category_id = category_id
        @min_amount = min_amount
        @max_amount = max_amount
        @search = search
        @categories = categories.presence || user.categories.top_level.with_subcategories.order(:name)
        super(**attrs)
      end

      def view_template
        div(
          id: "transactions_list",
          data: { transactions_pagination_target: "content" }
        ) do
          if @transactions.empty?
            render_empty_state
          else
            render_table
            render_pagination if @transactions.total_pages > 1
          end
        end
      end

      private

      def render_empty_state
        div(class: "flex h-32 flex-col items-center justify-center") do
          p(class: "text-sm text-muted-foreground") { "No transactions found" }
        end
      end

      def render_table
        Table do
          TableHeader do
            TableRow do
              render_sortable_header("date", class: "w-32")
              render_sortable_header("description")
              render_sortable_header("category", class: "w-40")
              render_sortable_header("value", class: "text-right w-32")
              TableHead(class: "w-16") { "" }
            end
          end
          TableBody(id: "transactions_table_body") do
            @transactions.each do |transaction|
              render ::Views::Banking::TransactionRow.new(transaction: transaction, categories: @categories)
            end
          end
        end
      end

      def render_sortable_header(column, **attrs)
        is_active = @sort_column == column
        new_direction = is_active && @sort_direction == "asc" ? "desc" : "asc"

        TableHead(**attrs) do
          a(
            href: sort_path(column, new_direction),
            class: "flex items-center gap-1 cursor-pointer hover:text-foreground transition-colors #{is_active ? 'text-foreground font-medium' : 'text-muted-foreground'}",
            data: {
              action: "click->transactions-pagination#showSpinner"
            }
          ) do
            plain SORTABLE_COLUMNS[column]
            render_sort_icon(column, is_active)
          end
        end
      end

      def render_sort_icon(column, is_active)
        if is_active
          if @sort_direction == "asc"
            render ::Components::Icon::ArrowUp.new(size: "14", class: "ml-1")
          else
            render ::Components::Icon::ArrowDown.new(size: "14", class: "ml-1")
          end
        else
          render ::Components::Icon::ArrowUpDown.new(size: "14", class: "ml-1 opacity-50")
        end
      end

      def sort_path(column, direction)
        params = { sort: column, direction: direction, page: 1 }
        params[:start_date] = @start_date.to_s if @start_date.present?
        params[:end_date] = @end_date.to_s if @end_date.present?
        params[:category_id] = @category_id if @category_id.present?
        params[:min_amount] = @min_amount if @min_amount.present?
        params[:max_amount] = @max_amount if @max_amount.present?
        params[:search] = @search if @search.present?
        view_context.banking_index_path(params)
      end

      def render_pagination
        div(class: "mt-6") do
          Pagination do
            PaginationContent do
              render_first_button
              render_prev_button
              render_page_numbers
              render_next_button
              render_last_button
            end
          end
        end
      end

      def render_first_button
        return if @transactions.first_page?

        PaginationItem(
          href: pagination_path(1),
          data: {
            action: "click->transactions-pagination#showSpinner"
          }
        ) do
          render ::Components::Icon::ChevronsLeft.new(size: "12", class: "w-5 h-5")
          plain("First")
        end
      end

      def render_prev_button
        return if @transactions.first_page?

        PaginationItem(
          href: pagination_path(@transactions.prev_page),
          data: {
            action: "click->transactions-pagination#showSpinner"
          }
        ) do
          render ::Components::Icon::ChevronLeft.new(size: "12", class: "w-5 h-5")
          plain("Prev")
        end
      end

      def render_next_button
        return if @transactions.last_page?

        PaginationItem(
          href: pagination_path(@transactions.next_page),
          data: {
            action: "click->transactions-pagination#showSpinner"
          }
        ) do
          render ::Components::Icon::ChevronRight.new(size: "12", class: "w-5 h-5")
          plain("Next")
        end
      end

      def render_last_button
        return if @transactions.last_page?

        PaginationItem(
          href: pagination_path(@transactions.total_pages),
          data: {
            action: "click->transactions-pagination#showSpinner"
          }
        ) do
          render ::Components::Icon::ChevronsRight.new(size: "12", class: "w-5 h-5")
          plain("Last")
        end
      end

      def render_page_numbers
        current_page = @transactions.current_page
        total_pages = @transactions.total_pages

        if total_pages <= 5
          (1..total_pages).each { |page_num| render_page_number(page_num, current_page) }
        else
          render_smart_page_numbers(current_page, total_pages)
        end
      end

      def render_smart_page_numbers(current_page, total_pages)
        render_page_number(1, current_page)
        PaginationEllipsis if current_page > 3

        start_page = [ current_page - 1, 2 ].max
        end_page = [ current_page + 1, total_pages - 1 ].min

        (start_page..end_page).each do |page_num|
          next if page_num == 1 || page_num == total_pages
          render_page_number(page_num, current_page)
        end

        PaginationEllipsis if current_page < total_pages - 2
        render_page_number(total_pages, current_page)
      end

      def render_page_number(page_num, current_page)
        PaginationItem(
          href: pagination_path(page_num),
          active: page_num == current_page,
          data: {
            action: "click->transactions-pagination#showSpinner"
          }
        ) { page_num.to_s }
      end

      def pagination_path(page)
        params = { page: page }
        params[:start_date] = @start_date.to_s if @start_date.present?
        params[:end_date] = @end_date.to_s if @end_date.present?
        params[:sort] = @sort_column if @sort_column.present?
        params[:direction] = @sort_direction if @sort_direction.present?
        params[:category_id] = @category_id if @category_id.present?
        params[:min_amount] = @min_amount if @min_amount.present?
        params[:max_amount] = @max_amount if @max_amount.present?
        params[:search] = @search if @search.present?
        view_context.banking_index_path(params)
      end
    end
  end
end
