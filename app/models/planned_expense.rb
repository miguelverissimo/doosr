# frozen_string_literal: true

class PlannedExpense < ApplicationRecord
  EXPENSE_TYPES = %w[one_time recurring_auto].freeze

  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :recurring_group, optional: true
  belongs_to :matched_transaction, class_name: "BankTransaction", optional: true

  validates :description, presence: true
  validates :expected_amount, presence: true, numericality: true
  validates :due_date, presence: true
  validates :expense_type, presence: true, inclusion: { in: EXPENSE_TYPES }

  scope :for_user, ->(user) { where(user: user) }
  scope :pending, -> { where(completed: false) }
  scope :completed, -> { where(completed: true) }
  scope :one_time, -> { where(expense_type: "one_time") }
  scope :recurring_auto, -> { where(expense_type: "recurring_auto") }
  scope :due_between, ->(start_date, end_date) { where(due_date: start_date..end_date) }
  scope :upcoming, -> { pending.where("due_date >= ?", Date.current).order(due_date: :asc) }
  scope :overdue, -> { pending.where("due_date < ?", Date.current).order(due_date: :asc) }

  def one_time?
    expense_type == "one_time"
  end

  def recurring_auto?
    expense_type == "recurring_auto"
  end

  def overdue?
    !completed && due_date < Date.current
  end

  def mark_completed!(transaction = nil)
    update!(completed: true, matched_transaction: transaction)
  end

  def expense_type_label
    case expense_type
    when "one_time" then "One-time"
    when "recurring_auto" then "Recurring"
    else expense_type.titleize
    end
  end
end
