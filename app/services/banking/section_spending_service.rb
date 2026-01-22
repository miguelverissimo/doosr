# frozen_string_literal: true

module Banking
  class SectionSpendingService
    SectionSpending = Struct.new(
      :section,
      :spent_this_month,
      :limit,
      :progress_percentage,
      :remaining,
      :over_limit,
      :subcategories_count,
      keyword_init: true
    )

    def initialize(user, reference_date: Date.current)
      @user = user
      @reference_date = reference_date
    end

    def call
      # Only load budget goals with their categories and subcategories
      budget_goals = @user.budget_goals.active.category_limits
        .includes(category: :subcategories)
        .order("categories.name")

      return [] if budget_goals.empty?

      period = current_period

      # Only preload spending for categories that have budget goals
      sections_with_limits = budget_goals.map(&:category)
      spending_by_category = preload_spending(sections_with_limits, period[:start], period[:end])

      budget_goals.map do |goal|
        section = goal.category
        category_ids = section.self_and_subcategory_ids
        spent = category_ids.sum { |id| spending_by_category[id] || 0.0 }
        limit = goal.target_amount.to_f

        progress_pct = limit.positive? ? [(spent / limit) * 100, 100].min : 0
        remaining = [limit - spent, 0].max
        over_limit = spent > limit

        SectionSpending.new(
          section: section,
          spent_this_month: spent,
          limit: limit,
          progress_percentage: progress_pct.round(1),
          remaining: remaining,
          over_limit: over_limit,
          subcategories_count: section.subcategories.size
        )
      end
    end

    private

    def current_period
      {
        start: @reference_date.beginning_of_month,
        end: @reference_date.end_of_month
      }
    end

    def preload_spending(sections, start_date, end_date)
      # Collect all category IDs (sections and their subcategories)
      all_category_ids = sections.flat_map(&:self_and_subcategory_ids).uniq

      # Single query to get all categorizations with their transactions
      categorizations = TransactionCategorization
        .joins(:bank_transaction)
        .includes(:bank_transaction)
        .where(category_id: all_category_ids)
        .where(bank_transactions: { user_id: @user.id, date: start_date..end_date })
        .where("bank_transactions.value < 0")

      # Build a hash of category_id => total spent
      spending_by_category = Hash.new(0.0)
      categorizations.each do |tc|
        amount = tc.amount.present? ? tc.amount.abs : tc.bank_transaction.value.abs
        spending_by_category[tc.category_id] += amount
      end

      spending_by_category
    end
  end
end
