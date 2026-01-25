# frozen_string_literal: true

module Banking
  class CategoryVarianceService
    CategoryAnalysis = Struct.new(
      :category,
      :monthly_average,
      :monthly_minimum,
      :monthly_maximum,
      :standard_deviation,
      :coefficient_of_variation,
      :is_variable,
      :reduction_potential,
      :monthly_amounts,
      keyword_init: true
    )

    VARIABLE_THRESHOLD = 0.3

    def initialize(user, months: 12)
      @user = user
      @months = months
    end

    def call
      analyze_all_categories
    end

    def analysis_for(category)
      analyze_category(category)
    end

    def variable_categories
      call.select(&:is_variable).sort_by { |a| -a.coefficient_of_variation }
    end

    def reduction_suggestions(target_amount:)
      suggestions = []
      remaining = target_amount.to_f

      variable_categories.each do |analysis|
        break if remaining <= 0 || analysis.reduction_potential <= 0

        reduction = [ analysis.reduction_potential, remaining ].min
        suggestions << {
          category: analysis.category,
          current_average: analysis.monthly_average,
          suggested_limit: analysis.monthly_average - reduction,
          reduction_amount: reduction,
          coefficient_of_variation: analysis.coefficient_of_variation
        }
        remaining -= reduction
      end

      suggestions
    end

    private

    def analyze_all_categories
      @user.categories.includes(:subcategories).map do |category|
        analyze_category(category)
      end.compact
    end

    def analyze_category(category)
      monthly_amounts = calculate_monthly_amounts(category)
      return nil if monthly_amounts.empty?

      avg = monthly_amounts.sum / monthly_amounts.size.to_f
      min = monthly_amounts.min
      max = monthly_amounts.max

      variance = monthly_amounts.map { |a| (a - avg)**2 }.sum / monthly_amounts.size
      std_dev = Math.sqrt(variance)
      cv = avg.positive? ? std_dev / avg : 0

      CategoryAnalysis.new(
        category: category,
        monthly_average: avg.round(2),
        monthly_minimum: min.round(2),
        monthly_maximum: max.round(2),
        standard_deviation: std_dev.round(2),
        coefficient_of_variation: cv.round(3),
        is_variable: cv > VARIABLE_THRESHOLD,
        reduction_potential: [ (avg - min), 0 ].max.round(2),
        monthly_amounts: monthly_amounts
      )
    end

    def calculate_monthly_amounts(category)
      end_date = Date.current.end_of_month
      start_date = (end_date - @months.months).beginning_of_month

      # Get category IDs including subcategories
      category_ids = category.self_and_subcategory_ids

      # Get all categorizations for this category and subcategories
      categorizations = TransactionCategorization
        .joins(:bank_transaction)
        .where(category_id: category_ids)
        .where(bank_transactions: { user_id: @user.id, date: start_date..end_date })
        .where("bank_transactions.value < 0")
        .includes(:bank_transaction)

      # Group by month and calculate totals
      monthly_totals = {}
      categorizations.find_each do |tc|
        month_key = tc.bank_transaction.date.beginning_of_month
        amount = tc.amount.present? ? tc.amount.abs : tc.bank_transaction.value.abs
        monthly_totals[month_key] ||= 0.0
        monthly_totals[month_key] += amount.to_f
      end

      # Return ordered monthly amounts
      monthly_totals.keys.sort.map { |k| monthly_totals[k] }
    end
  end
end
