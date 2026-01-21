# frozen_string_literal: true

class TransactionCategorization < ApplicationRecord
  belongs_to :bank_transaction
  belongs_to :category
  belongs_to :user

  validates :bank_transaction_id, uniqueness: { scope: :category_id }
  validate :amount_within_transaction_value, if: -> { amount.present? }
  validate :total_amounts_within_transaction_value

  scope :with_amount, -> { where.not(amount: nil) }
  scope :without_amount, -> { where(amount: nil) }

  private

  def amount_within_transaction_value
    return unless bank_transaction

    transaction_abs_value = bank_transaction.value.abs
    if amount.abs > transaction_abs_value
      errors.add(:amount, "cannot exceed transaction value (#{transaction_abs_value})")
    end
  end

  def total_amounts_within_transaction_value
    return unless bank_transaction

    transaction_abs_value = bank_transaction.value.abs

    other_amounts = bank_transaction.transaction_categorizations
      .where.not(id: id)
      .where.not(amount: nil)
      .sum(:amount)
      .to_f

    current_amount = amount.present? ? amount.abs : 0
    total = other_amounts + current_amount

    if total > transaction_abs_value
      errors.add(:amount, "total of all category amounts (#{total}) exceeds transaction value (#{transaction_abs_value})")
    end
  end
end
