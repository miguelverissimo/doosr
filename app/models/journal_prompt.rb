# frozen_string_literal: true

class JournalPrompt < ApplicationRecord
  belongs_to :user
  belongs_to :journal
  has_one :descendant, as: :descendable, dependent: :destroy

  validates :user, presence: true
  validates :journal, presence: true
  validates :prompt_text, presence: true

  after_create :create_descendant

  def parent_descendants
    tuple = { "JournalPrompt" => id }
    ::Descendant.where(
      "active_items @> ? OR inactive_items @> ?",
      [ tuple ].to_json,
      [ tuple ].to_json
    )
  end

  def prompt_preview
    prompt_text.truncate(100)
  end

  private

  def create_descendant
    return if descendant.present?
    build_descendant.save!
  end
end
