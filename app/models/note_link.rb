# frozen_string_literal: true

# NoteLink represents a link from one note to another note.
# This allows notes to reference each other for creating relationships.
#
class NoteLink < ApplicationRecord
  # Associations
  belongs_to :note
  belongs_to :linked_note, class_name: "Note"

  # Validations
  validates :note_id, uniqueness: { scope: :linked_note_id, message: "already links to this note" }
  validate :prevent_self_link

  private

  def prevent_self_link
    if note_id.present? && note_id == linked_note_id
      errors.add(:linked_note_id, "cannot link a note to itself")
    end
  end
end
