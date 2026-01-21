# frozen_string_literal: true

class RecurringGroup < ApplicationRecord
  FREQUENCIES = %w[weekly monthly yearly].freeze

  belongs_to :user
  has_many :bank_transactions, dependent: :nullify
  has_many :planned_expenses, dependent: :nullify

  validates :name, presence: true
  validates :description_pattern, presence: true, uniqueness: { scope: :user_id }
  validates :average_amount, presence: true, numericality: true
  validates :frequency, presence: true, inclusion: { in: FREQUENCIES }

  scope :active, -> { where(active: true) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_last_occurrence, -> { order(last_occurrence: :desc) }
  scope :expenses, -> { where("average_amount < 0") }
  scope :income, -> { where("average_amount > 0") }

  def monthly_amount
    case frequency
    when "weekly"
      average_amount * 4.33
    when "monthly"
      average_amount
    when "yearly"
      average_amount / 12.0
    else
      average_amount
    end
  end

  def frequency_label
    case frequency
    when "weekly" then "Weekly"
    when "monthly" then "Monthly"
    when "yearly" then "Yearly"
    else frequency.capitalize
    end
  end

  def future_occurrences(weeks: 12)
    return [] unless expected_next.present?

    occurrences = []
    current_date = expected_next
    end_date = Date.current + weeks.weeks

    while current_date <= end_date
      occurrences << current_date
      current_date = next_occurrence_after(current_date)
    end

    occurrences
  end

  def expense?
    average_amount.negative?
  end

  def income?
    average_amount.positive?
  end

  private

  def next_occurrence_after(date)
    case frequency
    when "weekly"
      date + 1.week
    when "monthly"
      date + 1.month
    when "yearly"
      date + 1.year
    else
      date + 1.month
    end
  end
end
