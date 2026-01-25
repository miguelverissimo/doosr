# frozen_string_literal: true

class BudgetGoal < ApplicationRecord
  GOAL_TYPES = %w[savings category_limit].freeze
  PERIODS = %w[weekly monthly quarterly yearly custom].freeze

  MONTH_NAMES = {
    1 => "January", 2 => "February", 3 => "March", 4 => "April",
    5 => "May", 6 => "June", 7 => "July", 8 => "August",
    9 => "September", 10 => "October", 11 => "November", 12 => "December"
  }.freeze

  QUARTERLY_MONTHS = [ 3, 6, 9, 12 ].freeze

  belongs_to :user
  belongs_to :category, optional: true

  validates :goal_type, presence: true, inclusion: { in: GOAL_TYPES }
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :period, presence: true, inclusion: { in: PERIODS }
  validate :category_required_for_category_limit
  validate :category_forbidden_for_savings
  validate :payment_months_required_for_custom

  scope :active, -> { where(active: true) }
  scope :for_user, ->(user) { where(user: user) }
  scope :savings_goals, -> { where(goal_type: "savings") }
  scope :category_limits, -> { where(goal_type: "category_limit") }

  def savings?
    goal_type == "savings"
  end

  def category_limit?
    goal_type == "category_limit"
  end

  def quarterly?
    period == "quarterly"
  end

  def custom?
    period == "custom"
  end

  def display_name
    return name if name.present?
    return category.name if category.present?

    savings? ? "Savings Goal" : "Budget Goal"
  end

  def period_label
    case period
    when "weekly" then "Weekly"
    when "monthly" then "Monthly"
    when "quarterly" then "Quarterly"
    when "yearly" then "Yearly"
    when "custom" then "Custom (#{payment_months_label})"
    else period.capitalize
    end
  end

  def payment_months_label
    return "" if effective_payment_months.empty?

    effective_payment_months.map { |m| MONTH_NAMES[m]&.first(3) }.compact.join(", ")
  end

  def effective_payment_months
    case period
    when "quarterly"
      QUARTERLY_MONTHS
    when "custom"
      payment_months.presence || []
    else
      []
    end
  end

  def effective_start_date
    start_date || created_at&.to_date || Date.current
  end

  def goal_type_label
    case goal_type
    when "savings" then "Savings"
    when "category_limit" then "Budget Limit"
    else goal_type.titleize
    end
  end

  def payments_per_year
    case period
    when "weekly" then 52
    when "monthly" then 12
    when "quarterly" then 4
    when "yearly" then 1
    when "custom" then effective_payment_months.size
    else 12
    end
  end

  def next_payment_date(from_date = Date.current)
    return nil unless %w[quarterly custom].include?(period)

    months = effective_payment_months
    return nil if months.empty?

    current_year = from_date.year
    current_month = from_date.month

    months.each do |month|
      date = Date.new(current_year, month, 1).end_of_month
      return date if date >= from_date
    end

    Date.new(current_year + 1, months.first, 1).end_of_month
  end

  def upcoming_payment_dates(count: 4, from_date: Date.current)
    return [] unless %w[quarterly custom].include?(period)

    dates = []
    current_date = from_date

    while dates.size < count
      next_date = next_payment_date(current_date)
      break unless next_date

      dates << next_date
      current_date = next_date + 1.day
    end

    dates
  end

  private

  def category_required_for_category_limit
    return unless category_limit? && category.nil?

    errors.add(:category, "is required for category limit goals")
  end

  def category_forbidden_for_savings
    return unless savings? && category.present?

    errors.add(:category, "must be blank for savings goals")
  end

  def payment_months_required_for_custom
    return unless custom? && (payment_months.blank? || payment_months.empty?)

    errors.add(:payment_months, "are required for custom schedule")
  end
end
