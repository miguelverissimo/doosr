# frozen_string_literal: true

module Banking
  class TransactionQueryService
    SORTABLE_COLUMNS = %w[date description category value].freeze
    DEFAULT_SORT_COLUMN = "date"
    DEFAULT_SORT_DIRECTION = "desc"
    CATEGORY_SORT_ASC = "categories.name ASC NULLS LAST, bank_transactions.id DESC"
    CATEGORY_SORT_DESC = "categories.name DESC NULLS LAST, bank_transactions.id DESC"

    Result = Struct.new(
      :transactions,
      :total_count,
      :total_income,
      :total_expenses,
      :net_balance,
      :income_change,
      :expenses_change,
      :balance_change,
      :category_breakdown,
      :time_series_data,
      :time_series_granularity,
      keyword_init: true
    )

    def initialize(user, params = {})
      @user = user
      @start_date = parse_date_param(params[:start_date], (Date.current - 3.months).beginning_of_month)
      @end_date = parse_date_param(params[:end_date], Date.current.end_of_month)
      @page = params[:page] || 1
      @per_page = params[:per_page] || 100
      @sort_column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT_COLUMN
      @sort_direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : DEFAULT_SORT_DIRECTION
      @category_id = params[:category_id]
      @breakdown_parent_id = params[:breakdown_parent_id]
      @min_amount = params[:min_amount]
      @max_amount = params[:max_amount]
      @search = params[:search]
      @bank_account_id = params[:bank_account_id]
    end

    def call
      base_transactions = build_base_query

      non_transfer_transactions = base_transactions.non_transfers
      total_income = non_transfer_transactions.where("value > 0").sum(:value)
      total_expenses = non_transfer_transactions.where("value < 0").sum(:value).abs
      net_balance = total_income - total_expenses

      previous_period_stats = compute_previous_period_stats(total_income, total_expenses, net_balance)

      category_breakdown = compute_category_breakdown(base_transactions)
      time_series_data, time_series_granularity = compute_time_series_data(base_transactions)

      total_count = base_transactions.count
      transactions = apply_sorting(base_transactions).page(@page).per(@per_page)

      Result.new(
        transactions: transactions,
        total_count: total_count,
        total_income: total_income,
        total_expenses: total_expenses,
        net_balance: net_balance,
        income_change: previous_period_stats[:income_change],
        expenses_change: previous_period_stats[:expenses_change],
        balance_change: previous_period_stats[:balance_change],
        category_breakdown: category_breakdown,
        time_series_data: time_series_data,
        time_series_granularity: time_series_granularity
      )
    end

    # Lightweight query without analytics (for API index, pattern controllers, etc.)
    def query
      base_transactions = build_base_query

      non_transfer_transactions = base_transactions.non_transfers
      total_income = non_transfer_transactions.where("value > 0").sum(:value)
      total_expenses = non_transfer_transactions.where("value < 0").sum(:value).abs
      net_balance = total_income - total_expenses

      total_count = base_transactions.count
      transactions = apply_sorting(base_transactions).page(@page).per(@per_page)

      Result.new(
        transactions: transactions,
        total_count: total_count,
        total_income: total_income,
        total_expenses: total_expenses,
        net_balance: net_balance
      )
    end

    # Access parsed params for view rendering
    attr_reader :start_date, :end_date, :page, :per_page, :sort_column, :sort_direction,
                :category_id, :breakdown_parent_id, :min_amount, :max_amount,
                :search, :bank_account_id

    private

    def build_base_query
      transactions = @user.bank_transactions
        .includes(:category_pattern, :bank_account, transaction_categorizations: :category)

      transactions = apply_date_filter(transactions)
      apply_filters(transactions)
    end

    def apply_date_filter(transactions)
      if @start_date && @end_date
        transactions.where(date: @start_date..@end_date)
      elsif @start_date
        transactions.where("date >= ?", @start_date)
      elsif @end_date
        transactions.where("date <= ?", @end_date)
      else
        transactions
      end
    end

    def apply_filters(transactions)
      transactions = apply_category_filter(transactions)
      transactions = apply_amount_filters(transactions)
      transactions = apply_search_filter(transactions)
      apply_bank_account_filter(transactions)
    end

    def apply_category_filter(transactions)
      if @breakdown_parent_id.present? && @category_id.blank?
        @categories_cache ||= @user.categories.includes(:subcategories, :parent).index_by(&:id)
        parent_category = @categories_cache[@breakdown_parent_id.to_i]
        if parent_category
          subcategory_ids = parent_category.subcategories.map(&:id)
          category_ids = [ parent_category.id ] + subcategory_ids
          return transactions.with_any_categorization(category_ids)
        end
      end

      return transactions if @category_id.blank?

      if @category_id == "uncategorized"
        transactions.without_categorizations
      else
        category = @user.categories.find_by(id: @category_id)
        return transactions unless category

        category_ids = category.self_and_subcategory_ids
        transactions.with_any_categorization(category_ids)
      end
    end

    def apply_amount_filters(transactions)
      if @min_amount.present?
        min = BigDecimal(@min_amount.to_s)
        transactions = transactions.where("ABS(value) >= ?", min)
      end
      if @max_amount.present?
        max = BigDecimal(@max_amount.to_s)
        transactions = transactions.where("ABS(value) <= ?", max)
      end
      transactions
    end

    def apply_search_filter(transactions)
      return transactions if @search.blank?

      transactions.where("LOWER(description) LIKE ?", "%#{@search.downcase}%")
    end

    def apply_bank_account_filter(transactions)
      return transactions if @bank_account_id.blank?

      if @bank_account_id == "none"
        transactions.where(bank_account_id: nil)
      else
        transactions.where(bank_account_id: @bank_account_id)
      end
    end

    def apply_sorting(transactions)
      case @sort_column
      when "category"
        order_sql = @sort_direction == "asc" ? CATEGORY_SORT_ASC : CATEGORY_SORT_DESC
        transactions
          .left_joins(transaction_categorizations: :category)
          .group("bank_transactions.id")
          .order(Arel.sql(order_sql))
      when "date"
        transactions.order(date: @sort_direction.to_sym, id: :desc)
      when "description"
        transactions.order(description: @sort_direction.to_sym, id: :desc)
      when "value"
        transactions.order(value: @sort_direction.to_sym, id: :desc)
      else
        transactions.order(date: :desc, id: :desc)
      end
    end

    def compute_category_breakdown(transactions)
      expense_ids = transactions.where("value < 0").pluck(:id)
      return [] if expense_ids.empty?

      @categories_cache ||= @user.categories.includes(:subcategories, :parent).index_by(&:id)

      if @breakdown_parent_id.present?
        return compute_subcategory_breakdown(expense_ids, @breakdown_parent_id)
      end

      category_amounts = TransactionCategorization
        .where(bank_transaction_id: expense_ids)
        .joins(:bank_transaction)
        .group(:category_id)
        .sum(Arel.sql("COALESCE(transaction_categorizations.amount, ABS(bank_transactions.value))"))

      categorized_transaction_ids = TransactionCategorization
        .where(bank_transaction_id: expense_ids)
        .distinct
        .pluck(:bank_transaction_id)

      category_totals = Hash.new(0.0)
      category_amounts.each do |category_id, amount|
        category = @categories_cache[category_id]
        next unless category

        top_level_id = category.parent_id || category_id
        category_totals[top_level_id] += amount.to_f
      end

      uncategorized_ids = expense_ids - categorized_transaction_ids
      if uncategorized_ids.any?
        uncategorized_total = BankTransaction.where(id: uncategorized_ids).sum("ABS(value)").to_f
        category_totals["uncategorized"] = uncategorized_total if uncategorized_total > 0
      end

      total_expenses = category_totals.values.sum
      return [] if total_expenses.zero?

      breakdown = category_totals.map do |category_id, amount|
        if category_id == "uncategorized"
          {
            id: "uncategorized",
            name: "Uncategorized",
            color: "#9CA3AF",
            amount: amount,
            percentage: ((amount / total_expenses) * 100).round(1),
            has_subcategories: false
          }
        else
          category = @categories_cache[category_id]
          {
            id: category_id,
            name: category&.name || "Unknown",
            color: category&.color || "#6B7280",
            amount: amount,
            percentage: ((amount / total_expenses) * 100).round(1),
            has_subcategories: category&.subcategories&.loaded? ? category.subcategories.size > 0 : false
          }
        end
      end

      breakdown.sort_by { |item| -item[:amount] }
    end

    def compute_subcategory_breakdown(expense_ids, parent_category_id)
      @categories_cache ||= @user.categories.includes(:subcategories, :parent).index_by(&:id)
      parent_category = @categories_cache[parent_category_id.to_i]
      return [] unless parent_category

      subcategory_ids = parent_category.subcategories.map(&:id)
      category_ids = [ parent_category.id ] + subcategory_ids

      category_amounts = TransactionCategorization
        .where(bank_transaction_id: expense_ids)
        .where(category_id: category_ids)
        .joins(:bank_transaction)
        .group(:category_id)
        .sum(Arel.sql("COALESCE(transaction_categorizations.amount, ABS(bank_transactions.value))"))

      total_expenses = category_amounts.values.sum.to_f
      return [] if total_expenses.zero?

      breakdown = category_amounts.map do |category_id, amount|
        category = @categories_cache[category_id]
        {
          id: category_id,
          name: category&.name || "Unknown",
          color: category&.color || "#6B7280",
          amount: amount.to_f,
          percentage: ((amount.to_f / total_expenses) * 100).round(1),
          has_subcategories: false,
          is_parent: category_id == parent_category.id
        }
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
        weeks << {
          label: current_week_start.strftime("%b %d"),
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

    def compute_previous_period_stats(total_income, total_expenses, net_balance)
      return { income_change: nil, expenses_change: nil, balance_change: nil } if @start_date.nil? || @end_date.nil?

      period_length = (@end_date - @start_date).to_i + 1
      prev_end_date = @start_date - 1.day
      prev_start_date = prev_end_date - period_length.days + 1.day

      prev_transactions = @user.bank_transactions
        .where(date: prev_start_date..prev_end_date)

      prev_income = prev_transactions.where("value > 0").sum(:value)
      prev_expenses = prev_transactions.where("value < 0").sum(:value).abs
      prev_balance = prev_income - prev_expenses

      {
        income_change: calculate_percentage_change(prev_income, total_income),
        expenses_change: calculate_percentage_change(prev_expenses, total_expenses),
        balance_change: calculate_percentage_change(prev_balance, net_balance)
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
end
