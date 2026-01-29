# frozen_string_literal: true

class BankAccount < ApplicationRecord
  belongs_to :user
  has_many :bank_transactions, dependent: :nullify

  ACCOUNT_TYPES = %w[checking savings credit_card investment other].freeze

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :account_type, presence: true, inclusion: { in: ACCOUNT_TYPES }
  validates :letter, length: { maximum: 2 }

  before_validation :set_default_letter, if: -> { letter.blank? && name.present? }

  scope :active, -> { where(active: true) }
  scope :for_user, ->(user) { where(user: user) }
  scope :ordered, -> { order(:name) }

  def display_letter
    letter.presence || name&.first&.upcase || "?"
  end

  private

  def set_default_letter
    self.letter = name.first.upcase if name.present?
  end
end
