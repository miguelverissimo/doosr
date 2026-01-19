# frozen_string_literal: true

class CategoryPattern < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :bank_transactions, dependent: :nullify

  validates :pattern, presence: true, uniqueness: { scope: :user_id }

  scope :for_user, ->(user) { where(user: user) }
  scope :by_length_desc, -> { order(Arel.sql("LENGTH(pattern) DESC")) }

  def matches?(description)
    description.to_s.downcase.include?(pattern.downcase)
  end
end
