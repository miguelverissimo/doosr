# frozen_string_literal: true

module Banking
  class ForecastService
    WeeklyProjection = Struct.new(
      :week_start,
      :week_end,
      :starting_balance,
      :recurring_income,
      :recurring_expenses,
      :planned_expenses,
      :variable_spending,
      :ending_balance,
      keyword_init: true
    )

    Warning = Struct.new(:type, :message, :week, :amount, keyword_init: true)

    Result = Struct.new(
      :current_balance,
      :weekly_projections,
      :warnings,
      :suggestions,
      :goal_progress,
      keyword_init: true
    )

    WEEKS_TO_PROJECT = 12

    def initialize(user)
      @user = user
      @goal_progress_service = GoalProgressService.new(user)
      @variance_service = CategoryVarianceService.new(user)
    end

    def call
      preload_data
      current_balance = calculate_current_balance
      projections = calculate_weekly_projections(current_balance)
      warnings = generate_warnings(projections)
      goal_progress = @goal_progress_service.call
      suggestions = generate_suggestions(projections, goal_progress)

      Result.new(
        current_balance: current_balance,
        weekly_projections: projections,
        warnings: warnings,
        suggestions: suggestions,
        goal_progress: goal_progress
      )
    end

    private

    def preload_data
      # Preload recurring groups with their future occurrences
      @income_groups = @user.recurring_groups.active.income.to_a
      @expense_groups = @user.recurring_groups.active.expenses.to_a

      # Pre-calculate occurrences for each group
      @income_occurrences = @income_groups.map do |group|
        [group, group.future_occurrences(weeks: WEEKS_TO_PROJECT)]
      end.to_h

      @expense_occurrences = @expense_groups.map do |group|
        [group, group.future_occurrences(weeks: WEEKS_TO_PROJECT)]
      end.to_h

      # Preload planned expenses for the entire projection period
      end_date = Date.current.beginning_of_week + WEEKS_TO_PROJECT.weeks
      @planned_expenses_by_week = @user.planned_expenses
        .pending
        .one_time
        .where(due_date: Date.current.beginning_of_week..end_date)
        .group_by { |pe| pe.due_date.beginning_of_week }
    end

    def calculate_current_balance
      @user.bank_transactions.sum(:value).to_f
    end

    def calculate_weekly_projections(starting_balance)
      projections = []
      balance = starting_balance

      WEEKS_TO_PROJECT.times do |i|
        week_start = Date.current.beginning_of_week + i.weeks
        week_end = week_start.end_of_week

        recurring_income = calculate_recurring_amount(week_start, week_end, income: true)
        recurring_expenses = calculate_recurring_amount(week_start, week_end, income: false)
        planned = calculate_planned_expenses(week_start, week_end)
        variable = estimate_variable_spending(week_start, week_end, recurring_expenses, planned)

        ending_balance = balance + recurring_income - recurring_expenses - planned - variable

        projections << WeeklyProjection.new(
          week_start: week_start,
          week_end: week_end,
          starting_balance: balance.round(2),
          recurring_income: recurring_income.round(2),
          recurring_expenses: recurring_expenses.round(2),
          planned_expenses: planned.round(2),
          variable_spending: variable.round(2),
          ending_balance: ending_balance.round(2)
        )

        balance = ending_balance
      end

      projections
    end

    def calculate_recurring_amount(week_start, week_end, income:)
      groups = income ? @income_groups : @expense_groups
      occurrences_map = income ? @income_occurrences : @expense_occurrences

      total = 0.0
      groups.each do |group|
        occurrences = occurrences_map[group]
        occurrences.each do |date|
          next unless date >= week_start && date <= week_end

          total += group.average_amount.abs
        end
      end
      total
    end

    def calculate_planned_expenses(week_start, week_end)
      expenses = @planned_expenses_by_week[week_start] || []
      expenses.sum(&:expected_amount).to_f
    end

    def estimate_variable_spending(week_start, week_end, recurring_expenses, planned_expenses)
      historical_weekly = calculate_historical_weekly_average

      recurring_weekly = @expense_groups.sum do |g|
        g.monthly_amount / 4.33
      end

      variable_weekly = [historical_weekly - recurring_weekly, 0].max

      already_covered = recurring_expenses + planned_expenses
      [variable_weekly - (already_covered / 7.0 * 7), 0].max
    end

    def calculate_historical_weekly_average
      start_date = Date.current - 12.weeks
      total_expenses = @user.bank_transactions
        .where(date: start_date..Date.current)
        .where("value < 0")
        .sum(:value)
        .to_f
        .abs

      total_expenses / 12.0
    end

    def generate_warnings(projections)
      warnings = []

      projections.each_with_index do |projection, index|
        if projection.ending_balance < 0
          warnings << Warning.new(
            type: :shortfall,
            message: "Projected shortfall of #{format_currency(projection.ending_balance.abs)}",
            week: projection.week_start,
            amount: projection.ending_balance.abs
          )
        elsif projection.ending_balance < 500
          warnings << Warning.new(
            type: :low_balance,
            message: "Low balance warning: #{format_currency(projection.ending_balance)}",
            week: projection.week_start,
            amount: projection.ending_balance
          )
        end
      end

      warnings
    end

    def generate_suggestions(projections, goal_progress)
      goals_at_risk = goal_progress.reject(&:on_track)
      return [] if goals_at_risk.empty?

      total_shortfall = goals_at_risk.sum(&:remaining_amount)

      @variance_service.reduction_suggestions(target_amount: total_shortfall)
    end

    def format_currency(amount)
      format("%.2f", amount)
    end
  end
end
