# frozen_string_literal: true

# Note represents a text note that can be attached to days, items, or other descendants.
# Notes can appear in multiple places via Descendant tuples: {"Note" => 123}
# Notes can link to other notes for creating relationships between notes.
#
class Note < ApplicationRecord
  # Associations
  belongs_to :user

  # Self-referential many-to-many for note linking
  has_many :note_links, dependent: :destroy
  has_many :linked_notes, through: :note_links, source: :linked_note
  has_many :reverse_note_links, class_name: "NoteLink", foreign_key: :linked_note_id, dependent: :destroy
  has_many :notes_linking_to_this, through: :reverse_note_links, source: :note

  # Validations
  validates :content, presence: true
  validates :user, presence: true

  # Scopes
  scope :for_user, ->(user) { where(user: user) }
  scope :ordered_by_date, -> { order(created_at: :desc) }
  scope :search, ->(query) { where("content ILIKE ?", "%#{query}%") if query.present? }

  # Find all descendants containing this note
  # Returns ActiveRecord::Relation of Descendant records
  def parent_descendants
    tuple = { "Note" => id }
    Descendant.where(
      "active_items @> ? OR inactive_items @> ?",
      [ tuple ].to_json,
      [ tuple ].to_json
    )
  end

  # Get a preview of the content (first 100 characters)
  def content_preview
    return "" if content.blank?
    content.length > 100 ? "#{content[0..97]}..." : content
  end

  # Check if this note is attached to any descendants
  def attached?
    parent_descendants.exists?
  end

  # Get all parent contexts (days, items, etc.)
  # Returns array of hashes: [{type: "Day", object: day}, {type: "Item", object: item}]
  def parent_contexts
    parent_descendants.includes(:descendable).map do |descendant|
      {
        type: descendant.descendable_type,
        object: descendant.descendable
      }
    end
  end
end
