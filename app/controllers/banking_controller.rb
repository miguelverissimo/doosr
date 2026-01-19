# frozen_string_literal: true

class BankingController < ApplicationController
  before_action :authenticate_user!
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) if request.format.html? }

  SORTABLE_COLUMNS = %w[date description category value].freeze
  DEFAULT_SORT_COLUMN = "date"
  DEFAULT_SORT_DIRECTION = "desc"

  def new_transaction
    @transaction = current_user.bank_transactions.build(date: Date.current)
    @categories = current_user.categories.order(:name)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Banking::TransactionFormDialog.new(
            transaction: @transaction,
            categories: @categories
          ), layout: false)
        )
      end
    end
  end

  def new_csv_import
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Banking::CsvImportDialog.new, layout: false)
        )
      end
    end
  end

  def import_csv
    csv_file = params[:csv_file]

    if csv_file.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "csv_import_form_errors",
            "<div class='text-sm text-destructive'>Please select a CSV file</div>"
          ), status: :unprocessable_entity
        end
      end
      return
    end

    csv_content = csv_file.read

    Banking::ImportJob.perform_later(current_user.id, csv_content)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("csv_import_dialog")
      end
    end
  end

  def create_transaction
    @transaction = current_user.bank_transactions.build(transaction_params)
    @transaction.row_hash = generate_row_hash(@transaction)

    if @transaction.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend(
            "transactions_table_body",
            render_to_string(::Views::Banking::TransactionRow.new(transaction: @transaction), layout: false)
          )
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "transaction_form_errors",
            "<div class='text-sm text-destructive'>#{@transaction.errors.full_messages.join(', ')}</div>"
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def edit_transaction
    @transaction = current_user.bank_transactions.find(params[:id])
    @categories = current_user.categories.order(:name)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Banking::TransactionFormDialog.new(
            transaction: @transaction,
            categories: @categories
          ), layout: false)
        )
      end
    end
  end

  def update_transaction
    @transaction = current_user.bank_transactions.find(params[:id])

    if @transaction.update(transaction_params)
      @transaction.update_column(:row_hash, generate_row_hash(@transaction))

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "transaction_#{@transaction.id}",
            render_to_string(::Views::Banking::TransactionRow.new(transaction: @transaction.reload, categories: current_user.categories.order(:name)), layout: false)
          )
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "transaction_form_errors",
            "<div class='text-sm text-destructive'>#{@transaction.errors.full_messages.join(', ')}</div>"
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def update_category
    @transaction = current_user.bank_transactions.find(params[:id])
    @categories = current_user.categories.order(:name)

    category_id = params.dig(:bank_transaction, :category_id)
    category_id = nil if category_id.blank?

    if @transaction.update(category_id: category_id)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "transaction_#{@transaction.id}_category",
            render_to_string(::Views::Banking::CategorySelector.new(
              transaction: @transaction.reload,
              categories: @categories,
              show_success: true
            ), layout: false)
          )
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          head :unprocessable_entity
        end
      end
    end
  end

  def destroy_transaction
    @transaction = current_user.bank_transactions.find(params[:id])
    @transaction.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("transaction_#{@transaction.id}")
      end
    end
  end

  def bulk_destroy
    ids = params[:ids].to_s.split(",").map(&:to_i)
    transactions = current_user.bank_transactions.where(id: ids)
    transaction_ids = transactions.pluck(:id)
    transactions.destroy_all

    respond_to do |format|
      format.turbo_stream do
        streams = transaction_ids.map do |id|
          turbo_stream.remove("transaction_#{id}")
        end
        render turbo_stream: streams
      end
    end
  end

  def index
    @start_date = parse_date_param(params[:start_date], nil)
    @end_date = parse_date_param(params[:end_date], nil)
    @page = params[:page] || 1
    @sort_column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT_COLUMN
    @sort_direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : DEFAULT_SORT_DIRECTION
    @category_id = params[:category_id]
    @min_amount = params[:min_amount]
    @max_amount = params[:max_amount]
    @search = params[:search]

    base_transactions = current_user.bank_transactions.includes(:category, :category_pattern)

    if @start_date && @end_date
      base_transactions = base_transactions.where(date: @start_date..@end_date)
    elsif @start_date
      base_transactions = base_transactions.where("date >= ?", @start_date)
    elsif @end_date
      base_transactions = base_transactions.where("date <= ?", @end_date)
    end

    base_transactions = apply_filters(base_transactions)

    @total_income = base_transactions.where("value > 0").sum(:value)
    @total_expenses = base_transactions.where("value < 0").sum(:value).abs
    @net_balance = @total_income - @total_expenses

    previous_period_stats = compute_previous_period_stats
    @income_change = previous_period_stats[:income_change]
    @expenses_change = previous_period_stats[:expenses_change]
    @balance_change = previous_period_stats[:balance_change]

    @category_breakdown = compute_category_breakdown(base_transactions)
    @time_series_data, @time_series_granularity = compute_time_series_data(base_transactions)

    @transactions = apply_sorting(base_transactions)
      .page(@page)
      .per(100)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "transactions_list",
          render_to_string(::Views::Banking::TransactionsList.new(
            user: current_user,
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
          ), layout: false)
        )
      end
      format.html do
        render ::Views::Banking::Index.new(
          user: current_user,
          start_date: @start_date,
          end_date: @end_date,
          total_income: @total_income,
          total_expenses: @total_expenses,
          net_balance: @net_balance,
          income_change: @income_change,
          expenses_change: @expenses_change,
          balance_change: @balance_change,
          category_breakdown: @category_breakdown,
          time_series_data: @time_series_data,
          time_series_granularity: @time_series_granularity,
          transactions: @transactions,
          page: @page,
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

  private

  def apply_filters(transactions)
    transactions = apply_category_filter(transactions)
    transactions = apply_amount_filters(transactions)
    transactions = apply_search_filter(transactions)
    transactions
  end

  def apply_category_filter(transactions)
    return transactions if @category_id.blank?

    if @category_id == "uncategorized"
      transactions.where(category_id: nil)
    else
      transactions.where(category_id: @category_id)
    end
  end

  def apply_amount_filters(transactions)
    if @min_amount.present?
      min = BigDecimal(@min_amount)
      transactions = transactions.where("ABS(value) >= ?", min)
    end
    if @max_amount.present?
      max = BigDecimal(@max_amount)
      transactions = transactions.where("ABS(value) <= ?", max)
    end
    transactions
  end

  def apply_search_filter(transactions)
    return transactions if @search.blank?

    transactions.where("LOWER(description) LIKE ?", "%#{@search.downcase}%")
  end

  def apply_sorting(transactions)
    order_clause = case @sort_column
    when "category"
      "categories.name #{@sort_direction} NULLS LAST, bank_transactions.id DESC"
    when "date"
      { date: @sort_direction.to_sym, id: :desc }
    when "description"
      { description: @sort_direction.to_sym, id: :desc }
    when "value"
      { value: @sort_direction.to_sym, id: :desc }
    else
      { date: :desc, id: :desc }
    end

    if @sort_column == "category"
      transactions.left_joins(:category).order(Arel.sql(order_clause))
    else
      transactions.order(order_clause)
    end
  end

  def transaction_params
    params.require(:bank_transaction).permit(:date, :description, :value, :category_id)
  end

  def generate_row_hash(transaction)
    normalized_value = transaction.value.to_s("F")
    data = "#{transaction.date.iso8601}|#{transaction.description.downcase}|#{normalized_value}"
    Digest::SHA256.hexdigest(data)
  end

  def compute_category_breakdown(transactions)
    expenses = transactions.where("value < 0")

    category_totals = expenses
      .group(:category_id)
      .sum(:value)

    total_expenses = category_totals.values.sum(&:abs)
    return [] if total_expenses.zero?

    categories_by_id = current_user.categories.index_by(&:id)

    breakdown = category_totals.map do |category_id, amount|
      if category_id.nil?
        {
          id: "uncategorized",
          name: "Uncategorized",
          color: "#9CA3AF",
          amount: amount.abs,
          percentage: ((amount.abs / total_expenses) * 100).round(1)
        }
      else
        category = categories_by_id[category_id]
        {
          id: category_id,
          name: category&.name || "Unknown",
          color: category&.color || "#6B7280",
          amount: amount.abs,
          percentage: ((amount.abs / total_expenses) * 100).round(1)
        }
      end
    end

    breakdown.sort_by { |item| -item[:amount] }
  end

  def compute_time_series_data(transactions)
    return [ [], :daily ] if transactions.empty?

    effective_start = @start_date || transactions.minimum(:date) || Date.current
    effective_end = @end_date || transactions.maximum(:date) || Date.current

    days_in_range = (effective_end - effective_start).to_i + 1
    granularity = determine_granularity(days_in_range)

    grouped_data = case granularity
    when :daily
      group_by_day(transactions, effective_start, effective_end)
    when :weekly
      group_by_week(transactions, effective_start, effective_end)
    when :monthly
      group_by_month(transactions, effective_start, effective_end)
    end

    [ grouped_data, granularity ]
  end

  def determine_granularity(days)
    if days <= 31
      :daily
    elsif days <= 90
      :weekly
    else
      :monthly
    end
  end

  def group_by_day(transactions, start_date, end_date)
    income_by_date = transactions.where("value > 0").group(:date).sum(:value)
    expenses_by_date = transactions.where("value < 0").group(:date).sum(:value)

    (start_date..end_date).map do |date|
      {
        label: date.strftime("%b %d"),
        income: (income_by_date[date] || 0).to_f.round(2),
        expenses: (expenses_by_date[date] || 0).abs.to_f.round(2)
      }
    end
  end

  def group_by_week(transactions, start_date, end_date)
    income_data = transactions
      .where("value > 0")
      .group("DATE_TRUNC('week', date)")
      .sum(:value)
      .transform_keys { |k| k.to_date }

    expenses_data = transactions
      .where("value < 0")
      .group("DATE_TRUNC('week', date)")
      .sum(:value)
      .transform_keys { |k| k.to_date }

    weeks = []
    current_week_start = start_date.beginning_of_week
    while current_week_start <= end_date
      week_end = [ current_week_start.end_of_week, end_date ].min
      weeks << {
        label: "#{current_week_start.strftime('%b %d')}",
        income: (income_data[current_week_start] || 0).to_f.round(2),
        expenses: (expenses_data[current_week_start] || 0).abs.to_f.round(2)
      }
      current_week_start += 1.week
    end
    weeks
  end

  def group_by_month(transactions, start_date, end_date)
    income_data = transactions
      .where("value > 0")
      .group("DATE_TRUNC('month', date)")
      .sum(:value)
      .transform_keys { |k| k.to_date }

    expenses_data = transactions
      .where("value < 0")
      .group("DATE_TRUNC('month', date)")
      .sum(:value)
      .transform_keys { |k| k.to_date }

    months = []
    current_month_start = start_date.beginning_of_month
    while current_month_start <= end_date
      months << {
        label: current_month_start.strftime("%b %Y"),
        income: (income_data[current_month_start] || 0).to_f.round(2),
        expenses: (expenses_data[current_month_start] || 0).abs.to_f.round(2)
      }
      current_month_start += 1.month
    end
    months
  end

  def compute_previous_period_stats
    return { income_change: nil, expenses_change: nil, balance_change: nil } if @start_date.nil? || @end_date.nil?

    period_length = (@end_date - @start_date).to_i + 1
    prev_end_date = @start_date - 1.day
    prev_start_date = prev_end_date - period_length.days + 1.day

    prev_transactions = current_user.bank_transactions
      .where(date: prev_start_date..prev_end_date)

    prev_income = prev_transactions.where("value > 0").sum(:value)
    prev_expenses = prev_transactions.where("value < 0").sum(:value).abs
    prev_balance = prev_income - prev_expenses

    {
      income_change: calculate_percentage_change(prev_income, @total_income),
      expenses_change: calculate_percentage_change(prev_expenses, @total_expenses),
      balance_change: calculate_percentage_change(prev_balance, @net_balance)
    }
  end

  def calculate_percentage_change(previous, current)
    return nil if previous.zero? && current.zero?
    return 100.0 if previous.zero? && current.positive?
    return -100.0 if previous.zero? && current.negative?

    ((current - previous) / previous.abs * 100).round(1)
  end

  def parse_date_param(param, default)
    return nil if param == "all"
    return default if param.blank?

    param.to_date
  rescue ArgumentError
    default
  end
end
