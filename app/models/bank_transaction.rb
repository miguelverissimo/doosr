# frozen_string_literal: true

class BankTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :category_pattern, optional: true
  belongs_to :recurring_group, optional: true
  belongs_to :bank_account, optional: true
  belongs_to :linked_transfer, class_name: "BankTransaction", optional: true

  has_many :transaction_categorizations, dependent: :destroy
  has_many :categories, through: :transaction_categorizations
  has_one :linked_from_transfer, class_name: "BankTransaction", foreign_key: :linked_transfer_id, dependent: :nullify

  validates :date, presence: true
  validates :description, presence: true
  validates :value, presence: true, numericality: true
  validates :row_hash, presence: true
  validate :row_hash_unique_within_scope

  scope :for_user, ->(user) { where(user: user) }
  scope :ordered_by_date, -> { order(date: :desc) }
  scope :expenses, -> { where("value < 0") }
  scope :income, -> { where("value > 0") }
  scope :in_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :for_category, ->(category) { with_categorization(category) }
  scope :uncategorized, -> { without_categorizations }
  scope :transfers, -> { where(is_transfer: true) }
  scope :non_transfers, -> { where(is_transfer: false) }
  scope :for_account, ->(account) { where(bank_account: account) }

  scope :with_categorization, ->(category) {
    joins(:transaction_categorizations)
      .where(transaction_categorizations: { category_id: category.id })
  }

  scope :with_any_categorization, ->(category_ids) {
    joins(:transaction_categorizations)
      .where(transaction_categorizations: { category_id: category_ids })
      .distinct
  }

  scope :without_categorizations, -> {
    left_joins(:transaction_categorizations)
      .where(transaction_categorizations: { id: nil })
  }

  def has_multiple_categories?
    transaction_categorizations.count > 1
  end

  def has_split_amounts?
    transaction_categorizations.with_amount.exists?
  end

  def total_categorized_amount
    transaction_categorizations.with_amount.sum(:amount)
  end

  def uncategorized_amount
    return value.abs if transaction_categorizations.empty?
    return 0 if transaction_categorizations.without_amount.exists?

    value.abs - total_categorized_amount
  end

  def primary_category
    transaction_categorizations.first&.category
  end

  def category_names
    transaction_categorizations.includes(:category).map { |tc| tc.category.name }
  end

  def set_categories(category_ids, amounts = {})
    transaction do
      transaction_categorizations.destroy_all

      category_ids.each do |cat_id|
        next if cat_id.blank?

        amount = amounts[cat_id.to_s]
        transaction_categorizations.create!(
          category_id: cat_id,
          user_id: user_id,
          amount: amount.presence
        )
      end
    end
  end

  def row_hash_unique_within_scope
    return if row_hash.blank?

    scope = if bank_account_id.present?
      self.class.where(bank_account_id: bank_account_id, row_hash: row_hash)
    else
      self.class.where(user_id: user_id, bank_account_id: nil, row_hash: row_hash)
    end

    scope = scope.where.not(id: id) if persisted?

    if scope.exists?
      errors.add(:row_hash, "has already been taken")
    end
  end
end
