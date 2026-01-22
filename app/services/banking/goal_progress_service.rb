# frozen_string_literal: true

module Banking
  class GoalProgressService
    GoalProgress = Struct.new(
      :goal,
      :current_amount,
      :target_amount,
      :progress_percentage,
      :remaining_amount,
      :on_track,
      :period_start,
      :period_end,
      :days_elapsed,
      :days_remaining,
      :next_payment_date,
      :upcoming_payments,
      keyword_init: true
    )

    def initialize(user, reference_date: Date.current)
      @user = user
      @reference_date = reference_date
    end

    def call
      @user.budget_goals.active.includes(category: :subcategories).map do |goal|
        calculate_progress(goal)
      end
    end

    def progress_for(goal)
      calculate_progress(goal)
    end

    private

    def calculate_progress(goal)
      period = period_for(goal)
      days_in_period = (period[:end] - period[:start]).to_i + 1
      days_elapsed = [(@reference_date - period[:start]).to_i + 1, days_in_period].min

      if goal.savings?
        calculate_savings_progress(goal, period, days_in_period, days_elapsed)
      else
        calculate_category_limit_progress(goal, period, days_in_period, days_elapsed)
      end
    end

    def calculate_savings_progress(goal, period, days_in_period, days_elapsed)
      transactions = @user.bank_transactions
        .where(date: period[:start]..@reference_date)

      income = transactions.where("value > 0").sum(:value).to_f
      expenses = transactions.where("value < 0").sum(:value).to_f.abs
      current_savings = income - expenses

      prorated_target = (goal.target_amount.to_f * days_elapsed) / days_in_period
      progress_pct = prorated_target.positive? ? [(current_savings / prorated_target) * 100, 100].min : 0

      GoalProgress.new(
        goal: goal,
        current_amount: current_savings,
        target_amount: goal.target_amount,
        progress_percentage: progress_pct.round(1),
        remaining_amount: [goal.target_amount - current_savings, 0].max,
        on_track: current_savings >= prorated_target,
        period_start: period[:start],
        period_end: period[:end],
        days_elapsed: days_elapsed,
        days_remaining: days_in_period - days_elapsed,
        next_payment_date: goal.next_payment_date,
        upcoming_payments: goal.upcoming_payment_dates(count: 4)
      )
    end

    def calculate_category_limit_progress(goal, period, days_in_period, days_elapsed)
      # Get category IDs including subcategories
      category_ids = goal.category.self_and_subcategory_ids

      # Query from transaction_categorizations table
      spent = calculate_category_spending(category_ids, period[:start], @reference_date)

      limit = goal.target_amount.to_f
      progress_pct = limit.positive? ? [(spent / limit) * 100, 100].min : 0

      prorated_limit = (limit * days_elapsed) / days_in_period
      on_track = spent <= prorated_limit

      GoalProgress.new(
        goal: goal,
        current_amount: spent,
        target_amount: limit,
        progress_percentage: progress_pct.round(1),
        remaining_amount: [limit - spent, 0].max,
        on_track: on_track,
        period_start: period[:start],
        period_end: period[:end],
        days_elapsed: days_elapsed,
        days_remaining: days_in_period - days_elapsed,
        next_payment_date: nil,
        upcoming_payments: []
      )
    end

    def calculate_category_spending(category_ids, start_date, end_date)
      # Get transactions with categorizations in the date range
      categorizations = TransactionCategorization
        .joins(:bank_transaction)
        .where(category_id: category_ids)
        .where(bank_transactions: { user_id: @user.id, date: start_date..end_date })
        .where("bank_transactions.value < 0")

      # Sum amounts: use specified amount if present, otherwise use full transaction value
      total = 0.0
      categorizations.includes(:bank_transaction).find_each do |tc|
        if tc.amount.present?
          total += tc.amount.abs
        else
          total += tc.bank_transaction.value.abs
        end
      end

      total
    end

    def period_for(goal)
      effective_start = goal.effective_start_date

      case goal.period
      when "weekly"
        start = @reference_date.beginning_of_week
        start = [start, effective_start].max
        { start: start, end: start.end_of_week }
      when "monthly"
        start = @reference_date.beginning_of_month
        start = [start, effective_start].max
        { start: start, end: start.end_of_month }
      when "quarterly"
        quarterly_period_for(goal, effective_start)
      when "yearly"
        start = @reference_date.beginning_of_year
        start = [start, effective_start].max
        { start: start, end: start.end_of_year }
      when "custom"
        custom_period_for(goal, effective_start)
      else
        start = @reference_date.beginning_of_month
        { start: start, end: start.end_of_month }
      end
    end

    def quarterly_period_for(goal, effective_start)
      current_quarter_month = (((@reference_date.month - 1) / 3) * 3) + 1
      quarter_start = Date.new(@reference_date.year, current_quarter_month, 1)

      if quarter_start < effective_start
        quarter_start = effective_start
      end

      quarter_end = (quarter_start + 2.months).end_of_month

      { start: quarter_start, end: quarter_end }
    end

    def custom_period_for(goal, effective_start)
      months = goal.effective_payment_months
      return { start: effective_start, end: @reference_date.end_of_month } if months.empty?

      previous_payment = find_previous_payment_date(months, @reference_date)
      next_payment = goal.next_payment_date(@reference_date)

      period_start = previous_payment ? previous_payment + 1.day : effective_start
      period_end = next_payment || @reference_date.end_of_year

      { start: period_start, end: period_end }
    end

    def find_previous_payment_date(months, from_date)
      current_year = from_date.year
      current_month = from_date.month

      months.reverse.each do |month|
        if month < current_month
          return Date.new(current_year, month, 1).end_of_month
        end
      end

      last_month = months.last
      return Date.new(current_year - 1, last_month, 1).end_of_month if last_month

      nil
    end
  end
end
