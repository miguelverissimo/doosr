# frozen_string_literal: true

class Journal < ApplicationRecord
  belongs_to :user
  has_one :descendant, as: :descendable, dependent: :destroy
  has_many :journal_prompts, dependent: :destroy
  has_many :journal_fragments, dependent: :destroy

  validates :user, presence: true
  validates :date, presence: true, uniqueness: { scope: :user_id, message: "already has a journal entry" }

  after_create :create_descendant

  scope :for_user, ->(user) { where(user: user) }
  scope :ordered_by_date, -> { order(date: :desc) }
  scope :search_by_date, ->(query) { where("date::text ILIKE ?", "%#{query}%") }

  def parent_descendants
    tuple = { "Journal" => id }
    ::Descendant.where(
      "active_items @> ? OR inactive_items @> ?",
      [ tuple ].to_json,
      [ tuple ].to_json
    )
  end

  def date_display
    date.strftime("%A, %B %d, %Y")
  end

  def attached?
    parent_descendants.exists?
  end

  def parent_contexts
    parent_descendants.map(&:descendable).compact
  end

  private

  def create_descendant
    return if descendant.present?
    build_descendant.save!
  end
end
