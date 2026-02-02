# frozen_string_literal: true

class Category < ApplicationRecord
  belongs_to :user
  belongs_to :parent, class_name: "Category", optional: true
  has_many :subcategories, class_name: "Category", foreign_key: "parent_id", dependent: :nullify

  has_many :transaction_categorizations, dependent: :destroy
  has_many :categorized_transactions, through: :transaction_categorizations, source: :bank_transaction
  has_many :category_patterns, dependent: :destroy
  has_many :budget_goals, dependent: :destroy
  has_many :planned_expenses, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: [ :user_id, :parent_id ] }
  validates :color, presence: true
  validate :parent_cannot_be_subcategory
  validate :cannot_have_deeply_nested_parent

  scope :top_level, -> { where(parent_id: nil) }
  scope :with_subcategories, -> { includes(:subcategories) }
  scope :ordered_hierarchically, -> { order(:name) }

  def top_level?
    parent_id.nil?
  end

  def subcategory?
    parent_id.present?
  end

  def full_name
    if parent
      "#{parent.name} → #{name}"
    else
      name
    end
  end

  def display_name_with_depth
    if subcategory?
      "  └ #{name}"
    else
      name
    end
  end

  def self_and_subcategory_ids
    [ id ] + subcategories.map(&:id)
  end

  def all_transaction_categorizations
    TransactionCategorization.where(category_id: self_and_subcategory_ids)
  end

  def effective_color
    color.presence || parent&.color || "#6B7280"
  end

  private

  def parent_cannot_be_subcategory
    return unless parent

    if parent.subcategory?
      errors.add(:parent, "cannot be a subcategory (only one level of nesting allowed)")
    end
  end

  def cannot_have_deeply_nested_parent
    return unless parent_id_changed? && parent

    if parent.parent_id.present?
      errors.add(:parent, "only one level of nesting is allowed")
    end
  end
end
