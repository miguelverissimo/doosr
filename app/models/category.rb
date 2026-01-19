class Category < ApplicationRecord
  belongs_to :user
  has_many :bank_transactions, dependent: :nullify
  has_many :category_patterns, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :color, presence: true
end
