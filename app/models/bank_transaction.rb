# frozen_string_literal: true

class BankTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :recurring_group, optional: true

  validates :date, presence: true
  validates :description, presence: true
  validates :value, presence: true, numericality: true
  validates :row_hash, presence: true, uniqueness: { scope: :user_id }

  scope :for_user, ->(user) { where(user: user) }
  scope :ordered_by_date, -> { order(date: :desc) }
  scope :expenses, -> { where("value < 0") }
  scope :income, -> { where("value > 0") }
  scope :in_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :for_category, ->(category) { where(category: category) }
  scope :uncategorized, -> { where(category_id: nil) }
end
