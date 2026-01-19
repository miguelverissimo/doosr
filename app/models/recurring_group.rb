# frozen_string_literal: true

class RecurringGroup < ApplicationRecord
  FREQUENCIES = %w[weekly monthly yearly].freeze

  belongs_to :user
  has_many :bank_transactions, dependent: :nullify

  validates :name, presence: true
  validates :description_pattern, presence: true, uniqueness: { scope: :user_id }
  validates :average_amount, presence: true, numericality: true
  validates :frequency, presence: true, inclusion: { in: FREQUENCIES }

  scope :active, -> { where(active: true) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_last_occurrence, -> { order(last_occurrence: :desc) }

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
end
