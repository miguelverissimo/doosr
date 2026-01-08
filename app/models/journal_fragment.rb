# frozen_string_literal: true

class JournalFragment < ApplicationRecord
  belongs_to :user
  belongs_to :journal

  validates :user, presence: true
  validates :journal, presence: true
  validates :content, presence: true

  def parent_descendants
    tuple = { "JournalFragment" => id }
    ::Descendant.where(
      "active_items @> ? OR inactive_items @> ?",
      [ tuple ].to_json,
      [ tuple ].to_json
    )
  end

  def content_preview
    content.truncate(100)
  end

  def rendered_markdown
    ApplicationController.helpers.render_markdown(content)
  end
end
